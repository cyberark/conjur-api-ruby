# Logging mechanism borrowed from rest-client
module Conjur
  # You can also configure logging by the environment variable CONJURAPI_LOG.
  def self.log= log
    @@log = create_log log
  end

  # Create a log that respond to << like a logger
  # param can be 'stdout', 'stderr', a string (then we will log to that file) or a logger (then we return it)
  def self.create_log param
    if param
      if param.is_a? String
        if param == 'stdout'
          stdout_logger = Class.new do
            def << obj
              STDOUT.write obj
            end
          end
          stdout_logger.new
        elsif param == 'stderr'
          stderr_logger = Class.new do
            def << obj
              STDERR.write obj
            end
          end
          stderr_logger.new
        else
          file_logger = Class.new do
            attr_writer :target_file

            def << obj
              File.open(@target_file, 'a') { |f| f.write obj }
            end
          end
          logger = file_logger.new
          logger.target_file = param
          logger
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