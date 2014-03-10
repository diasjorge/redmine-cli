require 'thor/group'
require 'pathname'

module Redmine::Cli::Generators
  class Install < Thor::Group
    include Thor::Actions

    def self.source_root
      File.dirname(__FILE__)
    end

    argument :url,          :type => :string
    argument :username,     :type => :string
    argument :password,     :type => :string
    argument :list_fields,  :type => :array
    class_option :test,  :type => :boolean
    def copy_configuration_file
      self.destination_root = File.expand_path("~") unless options.test
      template(".redmine")
    end
  end
end
