require 'thor'
require 'active_resource'
require 'active_support/core_ext/object/with_options'
require 'redmine-cli/config'

module Redmine
  module Cli
    class BaseResource < ActiveResource::Base
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
          end

          resources
        end
      end
    end

    class Issue   < BaseResource; end
    class User    < BaseResource; end
    class Project < BaseResource; end
  end
end
