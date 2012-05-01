#!/usr/bin/env ruby -wW2
# encoding: UTF-8

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib")
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'opee'
require 'relay'

class OpeeTest < ::Test::Unit::TestCase

  def test_opee_actor_queue
    a = ::Relay.new()
    assert_equal(0, a.queue_count())
    a.stop()
    a.ask(:relay, 5)
    assert_equal(1, a.queue_count())
    a.ask(:relay, 7)
    assert_equal(2, a.queue_count())
    a.close()
  end

  def test_opee_actor_ask
    a = ::Relay.new()
    a.ask(:relay, 7)
    sleep(0.5) # minimize dependencies for simplest possible test
    assert_equal(7, a.last_data)
    a.close()
  end

  def test_opee_actor_method_missing
    a = ::Relay.new()
    a.relay(7)
    ::Opee::Env.wait_close()
    assert_equal(7, a.last_data)
    a.close()
  end

  def test_opee_actor_really_missing
    a = ::Relay.new()
    assert_raise(NoMethodError) { a.xray(7) }
    a.close()
  end

  def test_opee_actor_raise_after_close
    a = ::Relay.new()
    a.close()
    assert_raise(ThreadError) { a.start() }
  end

  def test_opee_actor_priority
    a = ::Relay.new()
    a.priority_ask(:relay, 7)
    ::Opee::Env.wait_close()
    assert_equal(7, a.last_data)
    a.close()
  end

  def test_opee_actor_idle
    a = ::Relay.new()
    a.on_idle(:relay, 7)
    ::Opee::Env.wait_close()
    assert_equal(7, a.last_data)
    a.close()
  end

  def test_opee_actor_order
    a = ::Relay.new()
    a.stop()
    a.on_idle(:relay, 17)
    a.priority_ask(:relay, 3)
    a.ask(:relay, 7)
    a.step()
    assert_equal(3, a.last_data)
    a.step()
    assert_equal(7, a.last_data)
    a.step()
    assert_equal(17, a.last_data)
    a.close()
  end

end # OpeeTest
