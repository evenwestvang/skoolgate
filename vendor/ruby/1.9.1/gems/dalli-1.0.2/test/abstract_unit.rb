# Used to test the full Rails stack.
# Stolen from the Rails 3.0 source.
# Needed for the session store tests.
require 'active_support/core_ext/kernel/reporting'
require 'active_support/core_ext/string/encoding'
if "ruby".encoding_aware?
  # These are the normal settings that will be set up by Railties
  # TODO: Have these tests support other combinations of these values
  silence_warnings do
    Encoding.default_internal = "UTF-8"
    Encoding.default_external = "UTF-8"
  end
end

require 'test/unit'
require 'abstract_controller'
require 'action_controller'
require 'action_view'
require 'action_dispatch'
require 'active_support/dependencies'
require 'action_controller/caching'
require 'action_controller/caching/sweeping'

require 'pp' # require 'pp' early to prevent hidden_methods from not picking up the pretty-print methods until too late

module Rails
  def self.logger
    @logger ||= begin
      l = Logger.new(STDOUT)
      l.level = Logger::INFO; l
    end
  end
end

# Monkey patch the old routes initialization to be silenced.
class ActionDispatch::Routing::DeprecatedMapper
  def initialize_with_silencer(*args)
    ActiveSupport::Deprecation.silence { initialize_without_silencer(*args) }
  end
  alias_method_chain :initialize, :silencer
end

ActiveSupport::Dependencies.hook!

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true

ORIGINAL_LOCALES = I18n.available_locales.map {|locale| locale.to_s }.sort

module RackTestUtils
  def body_to_string(body)
    if body.respond_to?(:each)
      str = ""
      body.each {|s| str << s }
      str
    else
      body
    end
  end
  extend self
end

module SetupOnce
  extend ActiveSupport::Concern

  included do
    cattr_accessor :setup_once_block
    self.setup_once_block = nil

    setup :run_setup_once
  end

  module ClassMethods
    def setup_once(&block)
      self.setup_once_block = block
    end
  end

  private
    def run_setup_once
      if self.setup_once_block
        self.setup_once_block.call
        self.setup_once_block = nil
      end
    end
end

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

module ActiveSupport
  class TestCase
    include SetupOnce
    # Hold off drawing routes until all the possible controller classes
    # have been loaded.
    setup_once do
      SharedTestRoutes.draw do |map|
        # FIXME: match ':controller(/:action(/:id))'
        map.connect ':controller/:action/:id'
      end

      ActionController::IntegrationTest.app.routes.draw do |map|
        # FIXME: match ':controller(/:action(/:id))'
        map.connect ':controller/:action/:id'
      end
    end
  end
end

class RoutedRackApp
  attr_reader :routes

  def initialize(routes, &blk)
    @routes = routes
    @stack = ActionDispatch::MiddlewareStack.new(&blk).build(@routes)
  end

  def call(env)
    @stack.call(env)
  end
end

class BasicController
  attr_accessor :request

  def config
    @config ||= ActiveSupport::InheritableOptions.new(ActionController::Base.config).tap do |config|
      # VIEW TODO: View tests should not require a controller
      public_dir = File.expand_path("../fixtures/public", __FILE__)
      config.assets_dir = public_dir
      config.javascripts_dir = "#{public_dir}/javascripts"
      config.stylesheets_dir = "#{public_dir}/stylesheets"
      config
    end
  end
end

class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  setup do
    @routes = SharedTestRoutes
  end
end

class ActionController::IntegrationTest < ActiveSupport::TestCase
  def self.build_app(routes = nil)
    RoutedRackApp.new(routes || ActionDispatch::Routing::RouteSet.new) do |middleware|
      middleware.use "ActionDispatch::ShowExceptions"
      middleware.use "ActionDispatch::Callbacks"
      middleware.use "ActionDispatch::ParamsParser"
      middleware.use "ActionDispatch::Cookies"
      middleware.use "ActionDispatch::Flash"
      middleware.use "ActionDispatch::Head"
      yield(middleware) if block_given?
    end
  end

  self.app = build_app

  # Stub Rails dispatcher so it does not get controller references and
  # simply return the controller#action as Rack::Body.
  class StubDispatcher < ::ActionDispatch::Routing::RouteSet::Dispatcher
    protected
    def controller_reference(controller_param)
      controller_param
    end

    def dispatch(controller, action, env)
      [200, {'Content-Type' => 'text/html'}, ["#{controller}##{action}"]]
    end
  end

  def self.stub_controllers
    old_dispatcher = ActionDispatch::Routing::RouteSet::Dispatcher
    ActionDispatch::Routing::RouteSet.module_eval { remove_const :Dispatcher }
    ActionDispatch::Routing::RouteSet.module_eval { const_set :Dispatcher, StubDispatcher }
    yield ActionDispatch::Routing::RouteSet.new
  ensure
    ActionDispatch::Routing::RouteSet.module_eval { remove_const :Dispatcher }
    ActionDispatch::Routing::RouteSet.module_eval { const_set :Dispatcher, old_dispatcher }
  end

  def with_routing(&block)
    temporary_routes = ActionDispatch::Routing::RouteSet.new
    old_app, self.class.app = self.class.app, self.class.build_app(temporary_routes)
    old_routes = SharedTestRoutes
    silence_warnings { Object.const_set(:SharedTestRoutes, temporary_routes) }

    yield temporary_routes
  ensure
    self.class.app = old_app
    silence_warnings { Object.const_set(:SharedTestRoutes, old_routes) }
  end

  def with_autoload_path(path)
    path = File.join(File.dirname(__FILE__), "fixtures", path)
    if ActiveSupport::Dependencies.autoload_paths.include?(path)
      yield
    else
      begin
        ActiveSupport::Dependencies.autoload_paths << path
        yield
      ensure
        ActiveSupport::Dependencies.autoload_paths.reject! {|p| p == path}
        ActiveSupport::Dependencies.clear
      end
    end
  end
end

# Temporary base class
class Rack::TestCase < ActionController::IntegrationTest
  def self.testing(klass = nil)
    if klass
      @testing = "/#{klass.name.underscore}".sub!(/_controller$/, '')
    else
      @testing
    end
  end

  def get(thing, *args)
    if thing.is_a?(Symbol)
      super("#{self.class.testing}/#{thing}", *args)
    else
      super
    end
  end

  def assert_body(body)
    assert_equal body, Array.wrap(response.body).join
  end

  def assert_status(code)
    assert_equal code, response.status
  end

  def assert_response(body, status = 200, headers = {})
    assert_body   body
    assert_status status
    headers.each do |header, value|
      assert_header header, value
    end
  end

  def assert_content_type(type)
    assert_equal type, response.headers["Content-Type"]
  end

  def assert_header(name, value)
    assert_equal value, response.headers[name]
  end
end

class ActionController::Base
  def self.test_routes(&block)
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw(&block)
    include routes.url_helpers
  end
end

class ::ApplicationController < ActionController::Base
end

module ActionController
  class Base
    include ActionController::Testing
  end

  Base.view_paths = []

  class TestCase
    include ActionDispatch::TestProcess

    setup do
      @routes = SharedTestRoutes
    end
  end
end

# This stub emulates the Railtie including the URL helpers from a Rails application
module ActionController
  class Base
    include SharedTestRoutes.url_helpers
  end
end
