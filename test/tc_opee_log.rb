#!/usr/bin/env ruby -wW2
# encoding: UTF-8

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib")
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'stringio'
require 'opee'

class OpeeTest < ::Test::Unit::TestCase

  def test_opee_log_log
    stream = StringIO.new()
    ::Opee::Env.logger = ::Opee::Log.new(:stream => stream)
    ::Opee::Env.logger.severity = Logger::INFO
    ::Opee::Env.logger.formatter = proc { |sev, time, prog, msg| "#{sev}: #{msg}\n" }
    ::Opee::Env.log(Logger::FATAL, "dead")
    ::Opee::Env.log(Logger::ERROR, "oops")
    ::Opee::Env.log(Logger::WARN, "duck")
    ::Opee::Env.log(Logger::INFO, "something")
    ::Opee::Env.log(Logger::DEBUG, "bugs")
    ::Opee::Env.wait_close()
    assert_equal(%{FATAL: dead
ERROR: oops
WARN: duck
INFO: something
}, stream.string)
  end

  def test_opee_log_filename
    filename = 'filename_test.log'
    %x{rm -f #{filename}}
    ::Opee::Env.logger = ::Opee::Log.new(:filename => filename)
    ::Opee::Env.logger.severity = Logger::INFO
    ::Opee::Env.logger.formatter = proc { |sev, time, prog, msg| "#{sev}: #{msg}\n" }
    ::Opee::Env.info("first entry")
    ::Opee::Env.wait_close()
    output = File.read(filename).split("\n")[1..-1]
    assert_equal(['INFO: first entry'], output)
    %x{rm #{filename}}
  end

  def test_opee_log_set_filename
    filename = 'set_filename_test.log'
    %x{rm -f #{filename}}
    ::Opee::Env.logger.severity = Logger::INFO
    ::Opee::Env.logger.formatter = proc { |sev, time, prog, msg| "#{sev}: #{msg}\n" }
    ::Opee::Env.logger.set_filename(filename, 2, 1000)
    ::Opee::Env.info("first entry")
    ::Opee::Env.wait_close()
    output = File.read(filename).split("\n")[1..-1]
    assert_equal(['INFO: first entry'], output)
    %x{rm #{filename}}
  end

end # OpeeTest
