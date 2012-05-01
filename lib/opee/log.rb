
require 'logger'

module Opee
  class Log < Actor

    def initialize(options={})
      @logger = nil
      @forward = nil
      super(options)
    end

    def level()
      @logger.level
    end

    def formatter()
      @logger.formatter
    end

    def forward()
      @forward
    end

    private
    # Use ask() to invoke private methods. If called directly they will be
    # picked up by the Actor method_missing() method.

    def set_options(options)
      if !(filename = options[:filename]).nil?
        max_file_size = options.fetch(:max_file_size, options.fetch(:shift_size, 1048576))
        max_file_count = options.fetch(:max_file_count, options.fetch(:shift_age, 7))
        @logger = Logger.new(filename, max_file_count, max_file_size)
      elsif !(stream = options[:stream]).nil?
        @logger = Logger.new(stream)
      else
        @logger = Logger.new(STDOUT)
      end
      severity = options[:severity] if options.has_key?(:severity)
      formatter = options[:formatter] if options.has_key?(:formatter)
    end

    def log(severity, message)
      @logger.add(severity, message)
      @forward.log(severity, message) unless @forward.nil?
    end

    def stream=(stream)
      logger = Logger.new(stream)
      logger.level = @logger.level
      logger.formatter = @logger.formatter
      @logger = logger
    end

    def set_filename(filename, shift_age=7, shift_size=1048576)
      logger = Logger.new(filename, shift_age, shift_size)
      logger.level = @logger.level
      logger.formatter = @logger.formatter
      @logger = logger
    end

    def logger=(logger)
      @logger = logger
    end

    def forward=(forward_actor)
      @forward = forward_actor
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

    def formatter=(proc)
      @logger.formatter = proc
    end

  end # Log
end # Opee
