require 'ostruct'
require 'active_resource'
require 'ruby-debug'

class Issue < ActiveResource::Base

  def self.config
    @config ||= OpenStruct.new(YAML.load_file(File.expand_path("~/.redmine")))
  rescue Errno::ENOENT
    puts "You need to create the file .redmine in your home with your username, password and url"
    exit(1)
  end

  self.site = config.url
  self.user = config.username
  self.password = config.password
end

class Redmine < Thor
  desc "list", "List all issues for the user"
  method_option :assigned_to, :default => "me",  :aliases => "-at", :desc => "id of person the ticket is assigned to"
  method_option :all,         :type => :boolean, :aliases => "-a",  :desc => "list all tickets"
  def list
    params = {}

    unless options.all
      params[:assigned_to_id] = options.assigned_to
    end

    collection = Issue.all(:params => params)

    issues = collection.collect { |issue| [link_to_issue(issue.id), issue.subject, issue.status.name] }

    if issues.any?
      issues.insert(0, ["URL", "Subject", "Status"])
      print_table(issues)
    end
  end

  desc "show TICKET", "Display information of a ticket"
  def show(ticket)
    issue = Issue.find(ticket)

    display_issue(issue)
  rescue ActiveResource::ResourceNotFound
    say "No ticket with number: #{ticket}", :red
  end

  method_option :assigned_to, :aliases => "-at", :desc => "id of person the ticket is assigned to"
  method_option :status,      :aliases => "-s",  :desc => "status for ticket"
  method_option :project,     :aliases => "-p",  :desc => "project for the ticket"
  desc "new SUBJECT [DESCRIPTION]", "Create a new ticket"
  def new(subject, description="")
    options.subject     = subject
    options.description = description

    options.project ||= Issue.config.default_project_id

    issue = Issue.create(ticket_attributes(options))

    say "Created ticket: #{link_to_issue(issue.id)}", :green
  rescue ActiveResource::ResourceNotFound
    say "Could not create ticket with: #{options.inspect}", :red
  end

  method_option :status,      :aliases => "-s",  :desc => "status for ticket"
  method_option :subject,     :aliases => "-t",  :desc => "subject for ticket (title)"
  method_option :description, :aliases => "-d",  :desc => "description for ticket"
  method_option :assigned_to, :aliases => "-at", :desc => "id of person the ticket is assigned to"
  desc "update TICKET", "Update ticket status"
  def update(ticket)
    issue = Issue.find(ticket)
    if issue.update_attributes(ticket_attributes(options))
      say "Updated: #{ticket}. Options: #{options.inspect}", :green
      display_issue(issue)
    else
      say "Could not update ticket with: #{options.inspect}", :red
    end
  rescue ActiveResource::ResourceNotFound
    say "Could not find ticket: #{ticket}", :red
  end

  no_tasks do
    def link_to_issue(id)
      "#{Issue.config.url}/issues/#{id}"
    end

    def ticket_attributes(options)
      attributes = {}

      attributes[:subject]        = options.subject     if options.subject.present?
      attributes[:description]    = options.description if options.description.present?
      attributes[:project_id]     = options.project     if options.project
      attributes[:assigned_to_id] = options.assigned_to if options.assigned_to
      attributes[:status_id]      = options.status      if options.status

      attributes
    end

    def display_issue(issue)
      shell.print_wrapped "#{link_to_issue(issue.id)} - #{issue.status.name}"
      shell.print_wrapped "Subject: #{issue.subject}"
      shell.print_wrapped issue.description, :ident => 2
    end
  end
end
