require File.join(File.dirname(__FILE__), '..', 'routes.rb')
 
require 'rack/test'
require 'ruby-debug'
require 'rspec'
 
# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false