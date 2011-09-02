require 'thor'
require 'redmine-cli/config'
require 'redmine-cli/resources'
require 'redmine-cli/generators/install'
require 'yaml'

module Redmine
  module Cli
    class CLI < Thor
      desc "list", "List all issues for the user"
      method_option :assigned_to, :aliases => "-a",  :desc => "id or user name of person the ticket is assigned to"
      method_option :status,      :aliases => "-s",  :desc => "id or name of status for ticket"
      method_option :project,     :aliases => "-p",  :desc => "project id"
      method_option :std_output,  :aliases => "-o",  :type => :boolean,
                    :desc => "special output for STDOUT (useful for updates)"
      def list
        params = {}

        params[:assigned_to_id] = map_user(options.assigned_to) if options.assigned_to

        params[:status_id] = map_status(options.status) if options.status

        params[:project_id] = map_project(options.project) if options.project

        collection = Issue.fetch_all(params)

        unless options.std_output
          collection.sort! {|i,j| i.status.id <=> j.status.id }
          issues = collection.collect do |issue|
            assignee = ""
            assignee = issue.assigned_to.name if issue.respond_to?(:assigned_to)
            ["#{issue.id}", issue.status.name, issue.priority.name, assignee, issue.subject]
          end

          if issues.any?
            issues.insert(0, ["Id", "Status", "Priority", "Assignee", "Status"])
            print_table(issues)
            say "#{collection.count} issues - #{link_to_project(params[:project_id])}", :yellow
          end
        else
          say collection.collect(&:id).join(" ")
        end
      end

      desc "projects", "Lists all projects"
      def projects
          projects = Project.fetch_all.sort {|i,j| i.name <=> j.name}.collect { |project| [ project.id, project.identifier, project.name ] }
          if projects.any?
            projects.insert(0, ["Id", "Key", "Name"])
            print_table(projects)
            say "#{projects.count} projects - #{link_to_project}", :yellow
          end
          
      end

      desc "show TICKET", "Display information of a ticket"
      def show(ticket)
        issue = Issue.find(ticket)

        display_issue(issue)
      rescue ActiveResource::ResourceNotFound
        say "No ticket with number: #{ticket}", :red
      end

      method_option :assigned_to, :aliases => "-a",  :desc => "id or user name of person the ticket is assigned to"
      method_option :status,      :aliases => "-s",  :desc => "id or name of status for ticket"
      method_option :project,     :aliases => "-p", :desc => "project for the ticket"
      desc "new SUBJECT [DESCRIPTION]", "Create a new ticket"
      def new(subject, description="")
        params =
          Thor::CoreExt::HashWithIndifferentAccess.new(:subject => subject,
                                                       :description => description,
                                                       :project => Redmine::Cli::config.default_project_id)
        params.merge!(options)

        unless params.project
          raise "No default project specified"
        end

        issue = Issue.create(ticket_attributes(params))

        say "Created ticket: #{link_to_issue(issue.id)}", :green
      rescue ActiveResource::ResourceNotFound
        say "Could not create ticket with: #{options.inspect}", :red
      rescue RuntimeError => e
        say e.message, :red
      end

      method_option :tickets,     :aliases => "-l",  :desc => "list of tickets", :type => :array
      method_option :status,      :aliases => "-s",  :desc => "id or name of status for ticket"
      method_option :priority,    :aliases => "-p",  :desc => "id or name of priority for ticket"
      method_option :subject,     :aliases => "-t",  :desc => "subject for ticket (title)"
      method_option :description, :aliases => "-d",  :desc => "description for ticket"
      method_option :assigned_to, :aliases => "-a",  :desc => "id or user name of person the ticket is assigned to"
      desc "update [TICKETS]", "Update tickets"
      def update(*tickets)
        tickets = options.tickets if tickets.blank? && options.tickets.present?

        if tickets.empty?
          say "No tickets to update", :red
          exit 1
        end

        tickets.collect { |ticket| Thread.new { update_ticket(ticket, options) } }.each(&:join)
      end

      desc "install [URL] [USERNAME]", "Generates a default configuration file"
      method_option :test, :type => :boolean
      def install(url = "localhost:3000", username = "")
        url = "http://#{url}" unless url =~ /\Ahttp/

        if username.blank?
          username = ask("Username?")
        end

        password = ask_password("Password?")

        arguments = [url, username, password]
        arguments.concat(["--test"]) if options.test

        Redmine::Cli::Generators::Install.start(arguments)
      end

      no_tasks do
        def link_to_issue(id)
          "#{Redmine::Cli::config.url}/issues/#{id}"
        end

        def link_to_project(name = nil)
          if name
            "#{Redmine::Cli::config.url}/projects/#{name}/issues"
          else
            "#{Redmine::Cli::config.url}"
          end
        end

        def ticket_attributes(options)
          attributes = {}

          attributes[:subject]        = options.subject               if options.subject.present?
          attributes[:description]    = options.description           if options.description.present?
          attributes[:project_id]     = map_project(options.project)  if options.project.present?
          attributes[:assigned_to_id] = map_user(options.assigned_to) if options.assigned_to.present?
          attributes[:status_id]      = map_status(options.status)    if options.status.present?
          attributes[:priority_id]    = map_priority(options.priority)if options.priority.present?

          attributes
        end

        def display_issue(issue)
          shell.print_wrapped "#{link_to_issue(issue.id)} - #{issue.status.name}"
          shell.print_wrapped "Subject: #{issue.subject}"
          shell.print_wrapped issue.description || "", :ident => 2
        end

        def map_user(user_name)
          get_mapping(:user_mappings, user_name)
        end

        def map_status(status_name)
          get_mapping(:status_mappings, status_name)
        end

        def map_priority(priority_name)
          get_mapping(:priority_mappings, priority_name)
        end

        def map_project(project_name)
          get_mapping(:project_mappings, project_name)
        end

        def update_mapping_cache
          say 'Updating mapping cache...', :yellow
          # TODO: Updating user mapping requries Redmine 1.1+
          users = []
          begin
            users = User.fetch_all.collect { |user| [ user.login, user.id ] }
          rescue Exception => e
            say "Failed to fetch users: #{e}", :red
          end
          projects = Project.fetch_all.collect { |project| [ project.identifier, project.id ] }

          priorities = {}
          status = {}
          Issue.fetch_all.each do |issue|
              priorities[issue.priority.name] = issue.priority.id if issue.priority
              status[issue.status.name] = issue.status.id if issue.status
          end

          # TODO: Need to determine where to place cache file based on
          #       config file location.
          File.open(File.expand_path('~/.redmine_cache'), 'w') do |out|
            YAML.dump({
              :user_mappings => Hash[users],
              :project_mappings => Hash[projects],
              :priority_mappings => priorities,
              :status_mappings => status,
            }, out)
          end
        end

        def get_mapping_from_cache(mapping, value)
          begin
            if Redmine::Cli::cache[mapping].nil? || (mapped = Redmine::Cli::cache[mapping][value]).nil?
              return false
            end
            return mapped
          rescue
            # We need to recover here from any error that could happen
            # in case the cache is corrupted.
            return false
          end
        end

        def get_mapping(mapping, value)
          return value if value.to_i != 0

          if Redmine::Cli::config[mapping].nil? || (mapped = Redmine::Cli::config[mapping][value]).nil?
            if !(mapped = get_mapping_from_cache(mapping, value))
              update_mapping_cache

              if !(mapped = get_mapping_from_cache(mapping, value))
                say "No #{mapping} for #{value}", :red
                exit 1
              end
            end
          end

          return mapped
        end

        def update_ticket(ticket, options)
          issue = Issue.find(ticket)
          params = ticket_attributes(options)

          if issue.update_attributes(params)
            say "Updated: #{ticket}. Options: #{params.inspect}", :green
            display_issue(issue)
          else
            say "Could not update ticket with: #{params.inspect}", :red
          end
        rescue ActiveResource::ResourceNotFound
          say "Could not find ticket: #{ticket}", :red
        end

        def ask_password(prompt)
          system "stty -echo"
          password = ask(prompt)
          system "stty echo"
          password
        end

        def default_parameters
          {:limit => 100}
        end
      end
    end
  end
end
