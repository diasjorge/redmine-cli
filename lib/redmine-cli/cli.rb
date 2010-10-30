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

        unless options.std_output
          issues = collection.collect { |issue| [link_to_issue(issue.id), issue.subject, issue.status.name] }

          if issues.any?
            issues.insert(0, ["URL", "Subject", "Status"])
            print_table(issues)
          end
        else
          say collection.collect(&:id).join(",")
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

      method_option :tickets,     :aliases => "-l",  :desc => "list of tickets"
      method_option :status,      :aliases => "-s",  :desc => "id or name of status for ticket"
      method_option :subject,     :aliases => "-t",  :desc => "subject for ticket (title)"
      method_option :description, :aliases => "-d",  :desc => "description for ticket"
      method_option :assigned_to, :aliases => "-a",  :desc => "id or user name of person the ticket is assigned to"
      desc "update [TICKETS]", "Update tickets"
      def update(tickets = "")
        tickets = options.tickets if tickets.blank? && options.tickets.present?

        tickets = tickets.split(",")

        if tickets.empty?
          say "No tickets to update", :red
          exit 1
        end

        tickets.collect { |ticket| Thread.new { update_ticket(ticket, options) } }.each(&:join)
      end

      no_tasks do
        def link_to_issue(id)
          "#{Issue.config.url}/issues/#{id}"
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
          return value if value.to_i != 0

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

      end
    end
  end
end
