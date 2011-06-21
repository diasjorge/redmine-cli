require 'thor'
require 'yaml'

module Redmine
  module Cli
    class << self
      def config
        if File.file? '.redmine'
          config_file = '.redmine'
        else
          config_file = File.expand_path("~/.redmine")
        end

        @config ||=
          begin
            Thor::CoreExt::HashWithIndifferentAccess.new(YAML.load_file(config_file))
          rescue Errno::ENOENT
            puts "You need to create the file .redmine in your home with your username, password and url"
            Thor::CoreExt::HashWithIndifferentAccess.new
          end
      end
    end
  end
end
