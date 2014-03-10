require 'thor'
require 'redmine-cli/issue'
require 'redmine-cli/field'
require 'redmine-cli/generators/install'
require 'pp'

module Redmine
  module Cli
    class CLI < Thor

      desc "list", "List all issues for the user"
      method_option :assigned_to, :aliases => "-a",  :desc => "id or user name of person the ticket is assigned to"
      method_option :status,      :aliases => "-s",  :desc => "id or name of status for ticket"
      method_option :std_output,  :aliases => "-o",  :type => :boolean,
                    :desc => "special output for STDOUT (useful for updates)"

      def list
        params = {}

        params[:assigned_to_id] = map_user(options.assigned_to) if options.assigned_to

        params[:status_id] = map_status(options.status) if options.status

        collection = Issue.all(:params => params)

        selected_fields = Issue.config.list_fields

        unless options.std_output
          # Retrieve the list of issue fields in selected_fields
          issues = collection.collect { |issue| selected_fields.collect {| key |
            begin
              # If this is a built-in field for which we have a title, ref, and display method, use that.
              field = fields.fetch(key)
              if field.display
                value = issue.attributes.fetch(field.ref)
                field.display.call(value)
              else
                f = fields.fetch(key).ref
                issue.attributes.fetch(f)
              end
            rescue IndexError
              # Otherwise, let's look for a custom field by that name.
              issue.attributes[:custom_fields].collect { | field | 
                if field.attributes.fetch("name") == key
                  field.attributes.fetch("value")
                end
                #TODO: If the custom field doesn't exist, then we end up returning a blank value (not an error). I guess that's OK?
              }
            end

          }}

          if issues.any?
            issues.insert(0, selected_fields.collect {| key |
              begin
                fields.fetch(key).title
              rescue IndexError
                key
              end
            })
            print_table(issues)
          end
        else
          say collection.collect(&:id).join(" ")
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
                                                       :project => Issue.config.default_project_id)
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

      desc "install [URL] [USERNAME] [FIELDS]", "Generates a default configuration file"
      method_option :test, :type => :boolean
      def install(url = "localhost:3000", username = "", fieldcsv="")
        url = "http://#{url}" unless url =~ /\Ahttp/

        if username.blank?
          username = ask("Username?")
        end

        password = ask_password("Password?")

        if fieldcsv.blank?
          fieldcsv = ask("\nWhat fields should be displayed in \"redmine list\"?\n\nPossible values are: [" + fields.keys.join(", ") + "]\n\nEnter a list of comma-separated fields: ")
        end

        list_fields = fieldcsv.split(",")

        arguments = [url, username, password, list_fields]
        arguments.concat(["--test"]) if options.test

        Redmine::Cli::Generators::Install.start(arguments)
      end

      no_tasks do

        def link_to_issue(id)
          "#{Issue.config.url}/issues/#{id}"
        end

        def status_name(status)
           status.name
        end

        def ticket_attributes(options)
          attributes = {}

          attributes[:subject]        = options.subject               if options.subject.present?
          attributes[:description]    = options.description           if options.description.present?
          attributes[:project_id]     = options.project               if options.project.present?
          attributes[:assigned_to_id] = map_user(options.assigned_to) if options.assigned_to.present?
          attributes[:status_id]      = options.status                if options.status.present?

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

        def get_mapping(mapping, value)
          begin
            return value if value.to_i != 0
          rescue NoMethodError
            return value.attributes.fetch("name") if value.id.to_i != 0
          end
          
          if Issue.config[mapping].nil? || (mapped = Issue.config[mapping][value]).nil?
            say "No #{mapping} for #{value}", :red
            exit 1
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

        def fields()
          # This is a collection of built-in Redmine fields, the key by which they can be accessed, and a wrapper
          # method that is used to display their value. Pseudo-fields can be added that use different wrapper
          # methods to give the user flexibility over their output (see url vs. id)
          return {
            "url" => Field.new("URL", "id", method(:link_to_issue)),
            "id" => Field.new("ID#", "id"),
            "subject" => Field.new("Subject", "subject"),
            "status" => Field.new("Status", "status", method(:status_name)),
            "start_date" => Field.new("Start", "start_date"),
            "estimated_hours" => Field.new("Estd", "estimated_hours"),
            "tracker" => Field.new("Type", "tracker", method(:map_user)),
            "priority" => Field.new("Priority", "priority", method(:map_user)),
            "description" => Field.new("Description", "description"),
            "assigned_to" => Field.new("Assigned To", "assigned_to", method(:map_user)),
            "project" => Field.new("Project", "project", method(:map_user)),
            "author" => Field.new("Author", "author", method(:map_user)),
            "done_ratio" => Field.new("% Done", "done_ratio"),
            "due_date" => Field.new("Due On", "due_date"),
            "created_on" => Field.new("Created On", "created_on"),
            "updated_on" => Field.new("Updated On", "updated_on"),
          }
        end
      end
    end
  end
end
