require 'thor'
require 'active_resource'

module Redmine
  module Cli
    class Issue < ActiveResource::Base
      def self.config
        @config ||=
          begin
            Thor::CoreExt::HashWithIndifferentAccess.new(YAML.load_file(File.expand_path("~/.redmine")))
          rescue Errno::ENOENT
            puts "You need to create the file .redmine in your home with your username, password and url"
            Thor::CoreExt::HashWithIndifferentAccess.new
          end
      end

      self.site = config.url
      self.user = config.username
      self.password = config.password
    end
  end
end
