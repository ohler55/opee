#!/usr/bin/env ruby -wW2
# encoding: UTF-8

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib")
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'opee'
require 'relay'

class OpeeTest < ::Test::Unit::TestCase

  def test_opee_env_add_remove
    assert_equal(0, ::Opee::Env.actor_count)
    a = ::Relay.new()
    assert_equal(1, ::Opee::Env.actor_count)
    a.close()
    assert_equal(0, ::Opee::Env.actor_count)
  end

  def test_opee_env_each_actor
    a = ::Relay.new()
    b = ::Relay.new()
    c = ::Relay.new()
    all = []
    ::Opee::Env.each_actor { |x| all << x }
    assert_equal([a, b, c], all)
    a.close()
    b.close()
    c.close()
  end

  def test_opee_env_shutdown
    a = ::Relay.new()
    ::Opee::Env.shutdown
    assert_raise(ThreadError) { a.start() }
  end

  def test_opee_env_wait_close
    # chain 3 together to make sure all processing is completed
    a = ::Relay.new()
    b = ::Relay.new(:buddy => a)
    c = ::Relay.new(:buddy => b)
    c.ask(:relay, 7)
    ::Opee::Env.wait_close()
    assert_equal(7, a.last_data)
    a.close()
  end

  def test_opee_env_start_stop
    a = ::Relay.new()
    ::Opee::Env.stop()
    a.ask(:relay, 5)
    assert_equal(1, ::Opee::Env.queue_count())
    a.ask(:relay, 7)
    assert_equal(2, ::Opee::Env.queue_count())
    ::Opee::Env.start()
    ::Opee::Env.wait_close()
    assert_equal(7, a.last_data)
  end

end # OpeeTest
