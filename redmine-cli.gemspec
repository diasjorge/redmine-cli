# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redmine-cli/version"

Gem::Specification.new do |s|
  s.name        = "redmine-cli"
  s.version     = Redmine::Cli::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jorge Dias"]
  s.email       = ["jorge@mrdias.com"]
  s.homepage    = "http://rubygems.org/gems/redmine-cli"
  s.summary     = %q{Command line interface for redmine}
  s.description = %q{A simple command line interface for redmine for easy scripting}

  s.rubyforge_project = "redmine-cli"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activeresource", "~>3.0.0"
  s.add_dependency "thor"
  if RUBY_VERSION =~ /1.9/
    s.add_development_dependency "ruby-debug19"
  else
    s.add_development_dependency "ruby-debug"
  end
  s.add_development_dependency "rspec"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "aruba"
end
