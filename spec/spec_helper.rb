require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

require 'rubygems'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'spork'

Spork.prefork do
  # This file is copied to ~/spec when you run 'ruby script/generate rspec'
  # from the project root directory.
  ENV["CONJUR_ENV"] ||= 'test'
  
  # Allows loading of an environment config based on the environment
  require 'rspec'
  require 'webmock/rspec'
  require 'securerandom'
  
  # Uncomment the next line to use webrat's matchers
  #require 'webrat/integrations/rspec-rails'

  RSpec.configure do |config|
    # If you're not using ActiveRecord you should remove these
    # lines, delete config/database.yml and disable :active_record
    # in your config/boot.rb
    #config.use_transactional_fixtures = true
    #config.use_instantiated_fixtures  = false
    #config.fixture_path = File.join(redmine_root, 'test', 'fixtures')
  
    # == Fixtures
    #
    # You can declare fixtures for each example_group like this:
    #   describe "...." do
    #     fixtures :table_a, :table_b
    #
    # Alternatively, if you prefer to declare them only once, you can
    # do so right here. Just uncomment the next line and replace the fixture
    # names with your fixtures.
    #
    #
    # If you declare global fixtures, be aware that they will be declared
    # for all of your examples, even those that don't use them.
    #
    # You can also declare which fixtures to use (for example fixtures for test/fixtures):
    #
    # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
    #
    # == Mock Framework
    #
    # RSpec uses its own mocking framework by default. If you prefer to
    # use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    #
    # == Notes
    #
    # For more information take a look at Spec::Runner::Configuration and Spec::Runner
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
  
  # Requires supporting files with custom matchers and macros, etc,
  # in ./support/ and its subdirectories.
  Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}
end

shared_examples_for "http response" do
  let(:http_response) { mock(:response) }

  before(:each) do
    http_response.stub(:code).and_return 200
    http_response.stub(:message).and_return nil
    http_response.stub(:body).and_return http_json.to_json
  end
end

require 'conjur/api'

KIND="asset_kind"
ID="unique_id" 
ROLE='<role>'
MEMBER='<member>'
PRIVILEGE='<privilege>'
OWNER='<owner/userid>'
ACCOUNT='<core_account>'
OPTIONS={}

shared_context api: :dummy do
  let(:username) { "user" }
  let(:api){ Conjur::API.new_from_key username, 'key' }
  let(:authz_host) { 'http://authz.example.com' }
  let(:audit_host) { 'http://audit.example.com' }
  let(:credentials) { { headers: { authorization: "Token token=\"stub\"" } } } #, username: username } }
  let(:core_host) { 'http://core.example.com' }
  let(:account) { 'the-account' }

  before do
    Conjur::Authz::API.stub host: authz_host
    Conjur::Core::API.stub host: core_host
    Conjur::Core::API.stub conjur_account: account
    Conjur::Audit::API.stub host:audit_host
    Conjur.configuration.set :account, account
    api.stub credentials: credentials
  end
end

shared_context logging: :temp do
  let(:logfile) { Tempfile.new("log") }
  before { Conjur.log = logfile.path }
  let(:log) { logfile.read }
end
