
require 'logger'

module Opee
  class Log < Actor

    def initialize(options={})
      super(options)
    end

    private
    # use ask() to invoke private methods

    def set_options(options)
      @logger = Logger.new(STDOUT)
      severity = options[:severity] if options.has_key?(:severity)

      # TBD options for setting a file, severity, max_file_size, max_file_count, formatter
    end

    def severity=(level)
      if level.is_a?(String)
        severity = {
          'FATAL' => Logger::Severity::FATAL,
          'ERROR' => Logger::Severity::ERROR,
          'WARN' => Logger::Severity::WARN,
          'INFO' => Logger::Severity::INFO,
          'DEBUG' => Logger::Severity::DEBUG
        }[level]
        raise "#{level} is not a severity" if severity.nil?
        level = severity
      elsif level < Logger::Severity::DEBUG || Logger::Severity::FATAL < level
        raise "#{level} is not a severity"
      end
      @logger.level = level
    end

    def log(severity, message)
      @logger.add(severity, message)
    end

  end # Log
end # Opee
