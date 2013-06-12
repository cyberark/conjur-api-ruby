require 'logger'

module Conjur
  # You can also configure logging by the environment variable CONJURAPI_LOG.
  def self.log= log
    @@log = create_log log
  end

  def self.create_log param
    if param
      if param.is_a? String
        if param == 'stdout'
          Logger.new $stdout
        elsif param == 'stderr'
          Logger.new $stderr
        else
          Logger.new param
        end
      else
        param
      end
    end
  end

  @@env_log = create_log ENV['CONJURAPI_LOG']

  @@log = nil

  def self.log # :nodoc:
    @@env_log || @@log
  end
end
