#!/usr/bin/env ruby -wW1
# encoding: UTF-8

$: << File.join(File.dirname(__FILE__), "../lib")

require 'test/unit'
require 'opee'
require 'relay'

class Opeet < ::Test::Unit::TestCase

  def test_ask_queue
    a = ::Relay.new(nil)
    assert_equal(0, a.queue_count())
    a.stop()
    a.ask(:relay, 7)
    assert_equal(1, a.queue_count())
    a.start()
    sleep(0.5)
    assert_equal(7, a.last_data)
    a.close()
  end

  def test_log
    #::Opee::Env.logger.ask(:severity=, Logger::INFO)
    ::Opee::Env.logger.severity= Logger::INFO
    ::Opee::Env.log(Logger::INFO, "hello")
    ::Opee::Env.each_actor { |a| puts a.to_s }
    sleep(0.2)
  end

  def test_wait_close
    a = ::Relay.new(nil)
    a.ask(:relay, 7)
    ::Opee::Env.wait_close()
    assert_equal(7, a.last_data)
    a.close()
  end

end # Opeet
