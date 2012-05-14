
require 'logger'

module Opee
  # An asynchronous logger build on top of the Actor class. It is able to log
  # messages as well as forward calls to a {#forward} Actor.
  class Log < Actor

    def initialize(options={})
      @logger = nil
      @forward = nil
      super(options)
    end

    # Returns the current severity level.
    # @return [Fixnum] Logger severity level
    def level()
      @logger.level
    end

    # Returns the current formatter.
    # @return [Logger::Formatter] current formatter
    def formatter()
      @logger.formatter
    end

    # Returns the forward Log Actor if one has been set.
    # @return [Log] the forward Log Actor if set
    def forward()
      @forward
    end

    private
    # Use ask() to invoke private methods. If called directly they will be
    # picked up by the Actor method_missing() method.

    # Sets the logger, severity, and formatter if provided.
    # @param [Hash] options options to be used for initialization
    # @option options [String] :filename filename to write to
    # @option options [Fixnum] :max_file_size maximum file size
    # @option options [Fixnum] :max_file_count maximum number of log file
    # @option options [IO] :stream IO stream
    # @option options [String|Fixnum] :severity initial setting for severity
    # @option options [Proc] :formatter initial setting for the formatter procedure
    def set_options(options)
      super(options)
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

    # Writes a message if the severity is high enough. This method is
    # executed asynchronously.
    # @param [Fixnum] severity one of the Logger levels
    # @param [String] message string to log
    def log(severity, message)
      @logger.add(severity, message)
      @forward.log(severity, message) unless @forward.nil?
    end

    # Sets the logger to use the stream specified. This method is executed
    # asynchronously.
    # @param [IO] stream stream to write log messages to
    def stream=(stream)
      logger = Logger.new(stream)
      logger.level = @logger.level
      logger.formatter = @logger.formatter
      @logger = logger
    end

    # Creates a new Logger to write log messages to using the parameters
    # specified. This method is executed asynchronously.
    # @param [String] filename filename of active log file
    # @param [Fixmun] shift_age maximum number of archive files to save
    # @param [Fixmun] shift_size maximum file size
    def set_filename(filename, shift_age=7, shift_size=1048576)
      logger = Logger.new(filename, shift_age, shift_size)
      logger.level = @logger.level
      logger.formatter = @logger.formatter
      @logger = logger
    end

    # Replace the logger with a new Logger Object. This method is executed
    # asynchronously.
    # @param [Logger] logger replacement logger
    def logger=(logger)
      @logger = logger
    end

    # Sets the {#forward} to the actor specified. This method is executed
    # asynchronously.
    # @param [Log] forward_actor Log Actor to forward log calls to
    def forward=(forward_actor)
      @forward = forward_actor
    end

    # Sets the severity level of the logger. This method is executed
    # asynchronously.
    # @param [String|Fixnum] level value to set the severity to
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

    # Sets the formatter procedure of the logger. This method is executed
    # asynchronously.
    # @param [Proc] proc value to set the formatter to
    def formatter=(proc)
      @logger.formatter = proc
    end

  end # Log
end # Opee
