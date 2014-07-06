#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module Conjur
  
  class << self
    def configuration
      @config ||= Configuration.new
    end
    
    def configuration=(config)
      @config = config
    end
  end
  
  class Configuration
    class << self
      # @api private
      def accepted_options
        require 'set'
        @options ||= Set.new
      end
      
      # @param [Symbol] name
      # @param [Hash] options
      # @option options [Boolean] :boolean (false) whether this option should have a '?' accessor 
      # @option options [Boolean, String] :env Environment variable for this option.  Set to false
      #   to disallow environment based configuration.  Default is CONJUR_<OPTION_NAME>.
      # @option options [Proc, *] :default Default value or proc to provide it
      # @option options [Boolean] :required (false) when true, raise an exception if the option is
      #   not set
      # @option options [Boolean] :sticky (true) when false, default proc will be called every time, 
      #   otherwise the proc's result will be cached
      # @option options [Proc, #to_proc] :convert proc-ish to convert environment 
      #   values to appropriate types
      # @param [Proc] def_proc block to provide default values 
      # @api private
      def add_option name, options = {}, &def_proc
        accepted_options << name
        allow_env = options[:env].nil? || options[:env]
        sticky = options.member?(:sticky) ? options[:sticky] : true
        env_var = options[:env] || "CONJUR_#{name.to_s.upcase}"
        def_val = options[:default]
        opt_name = name
        
        def_proc ||= if def_val.respond_to?(:call)
          def_val
        elsif options[:required]
          proc { raise "Missing required option #{opt_name}" }
        else
          proc { def_val }
        end
        
        convert = options[:convert] || ->(x){ x }
        # Allow a Symbol, for example
        convert = convert.to_proc if convert.respond_to?(:to_proc) 

        define_method("#{name}=") do |value|
          set name, value
        end
        
        define_method(name) do
          if supplied.member?(name)
            supplied[name]
          elsif allow_env && ENV.member?(env_var)
            instance_exec(ENV[env_var], &convert)
          else 
            value = instance_eval(&def_proc)
            supplied[name] = value if sticky
            value
          end
        end
        alias_method("#{name}?", name) if options[:boolean]
      end
    end

    def set(key, value)
      if self.class.accepted_options.include?(key.to_sym)
        supplied[key.to_sym] = value
      end
    end
    
    add_option :authn_url do
      account_service_url 'authn', 0
    end
    
    add_option :authz_url do
      global_service_url  'authz', 100
    end

    add_option :core_url do
      default_service_url 'core', 200
    end    
    
    add_option :audit_url do
      global_service_url  'audit', 300
    end    
    
    add_option :appliance_url
    
    add_option :service_base_port, default: 5000

    add_option :account, required: true
    
    add_option :env do
      ENV['RAILS_ENV'] || ENV['RACK_ENV'] || "production"
    end
    
    add_option :stack do
      case env
      when "production"
        "v4"
      else
        env
      end
    end
    
    private

    def global_service_url(service_name, service_port_offset)
      if appliance_url
        URI.join(appliance_url + '/', service_name).to_s
      else
        case env
        when 'test', 'development', 'appliance'
          "http://localhost:#{service_base_port + service_port_offset}"
        else
          "https://#{service_name}-#{stack}-conjur.herokuapp.com"
        end
      end
    end
    
    def account_service_url(service_name, service_port_offset)
      if appliance_url
        URI.join(appliance_url + '/', service_name).to_s
      else
        case env
        when 'test', 'development', 'appliance'
          "http://localhost:#{service_base_port + service_port_offset}"
        else
          "https://#{service_name}-#{account}-conjur.herokuapp.com"
        end
      end
    end
    
    def default_service_url(service_name, service_port_offset)
      if appliance_url
        appliance_url
      else
        account_service_url(service_name, service_port_offset)
      end
    end
    
    def supplied
      @supplied ||= {}
    end
  end
end
