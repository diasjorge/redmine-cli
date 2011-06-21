require 'thor'
require 'active_resource'
require 'redmine-cli/config'

module Redmine
  module Cli
    class Issue < ActiveResource::Base
      self.site = Redmine::Cli::config.url
      self.user = Redmine::Cli::config.username
      self.password = Redmine::Cli::config.password
    end
  end
end
