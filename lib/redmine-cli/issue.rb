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

class Hash
  class << self
    alias_method :from_xml_original, :from_xml
    def from_xml(xml)
      scrubbed = scrub_attributes(xml)
      from_xml_original(scrubbed)
    end
    def scrub_attributes(xml)
      xml.gsub(/<issues .*?>/, "<issues type=\"array\">")
    end
  end
end
