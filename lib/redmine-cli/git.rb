require 'thor'
require 'redmine-cli/issue'

module Redmine
  module Cli
    class Git < Thor

      desc "new TICKET", "Generate branch from ticket's information"
      def new(ticket)
        issue = Issue.find(ticket)
        subject = issue.subject.gsub(/[^a-z0-9\-]+/i, "-").gsub(/-{1,}/,'-').gsub(/-$|^-/, '').downcase
        `git checkout -b #{ticket}-#{subject}`
      rescue ActiveResource::ResourceNotFound
        say "No ticket with number: #{ticket}", :red
      end

    end
  end
end
