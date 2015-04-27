require 'thor'
require 'active_resource'
require 'active_support/core_ext/object/with_options'
require 'redmine-cli/config'
require 'pp'

module Redmine
  module Cli
    class BaseResource < ActiveResource::Base
      begin
        self.site = Redmine::Cli::config.url
        self.user = Redmine::Cli::config.username
        self.password = Redmine::Cli::config.password
  
        class << self
          # HACK: Redmine API isn't ActiveResource-friendly out of the box, so
          # we need to pass nometa=1 to all requests since we don't care about
          # the metadata that gets passed back in the top level attributes.
          def find(*arguments)
            arguments[1] = arguments[1] || {}
            arguments[1][:params] = arguments[1][:params] || {}
            arguments[1][:params][:nometa] = 1
  
            super
          end
  
          def fetch_all(params = {})
            limit  = 100
            offset = 0
  
            resources = []
  
            while((fetched_resources = self.all(:params => params.merge({:limit => limit, :offset => offset}))).any?)
              resources += fetched_resources
              offset    += limit
              if fetched_resources.length < limit then
                break
              end
            end
  
            resources
          end
        end
      rescue NoConfigFileError
        puts "Warning: No .redmine file was found in your home directory. Use \"redmine install\" to create one."
      end
    end

    class Issue   < BaseResource; end
    class User    < BaseResource; end
    class Project < BaseResource; end
    class Query < BaseResource; end
  end
end


# HACK: Redmine API isn't ActiveResource-friendly out of the box, and
# also some versions of Redmine ignore the nometa=1 parameter. So we
# need to manually strip out metadata that confuses ActiveResource.
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
