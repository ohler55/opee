#!/usr/bin/env ruby -wW2
# encoding: UTF-8

[ File.dirname(__FILE__),
  File.join(File.dirname(__FILE__), "../lib")
].each { |path| $: << path unless $:.include?(path) }

require 'test/unit'
require 'opee'

class NotJob
  attr_reader :a, :b, :c

  def initialize()
    @a = []
    @b = []
    @c = []
  end

end # NotJob

class NiceJob < ::Opee::Job
  attr_reader :a, :b, :c

  def initialize(next_actor)
    @next_actor = next_actor
    @a = []
    @b = []
    @c = []
  end

  def update_token(token, path_id)
    token = [] if token.nil?
    token << path_id
    token
  end

  def complete?(token)
    3 <= token.size && token.include?(:a) && token.include?(:b) && token.include?(:c)
  end

  def keep_going()
    @next_actor.ask(:done, self)
  end

end # NiceJob

class Fan < ::Opee::Actor
  private

  def set_options(options)
    super(options)
    @fans = options[:fans]
  end

  def go(job)
    @fans.each { |f| f.ask(:set, job) }
  end

end # Fan

class Setter < ::Opee::Actor
  private

  def set_options(options)
    super(options)
    @attr = options[:attr]
    @forward = options[:forward]
  end

  def set(job)
    job.send(@attr) << true
    @forward.ask(:collect, job, @attr)
  end

end # Setter

class Col < ::Opee::Collector
  private

  def set_options(options)
    super(options)
    @done = options[:done]
  end

  def job_key(job)
    job.object_id()
  end

  def update_token(job, token, path_id)
    token.to_i + 1
  end

  def complete?(job, token)
    3 <= token
  end

end # Col

class Done < ::Opee::Actor
  attr_reader :finished

  def initialize(options={})
    @finished = false
    super
  end

  private

  def done(job)
    @finished = true
  end

end # Done

class OpeeTest < ::Test::Unit::TestCase

  def test_opee_collector
    done = Done.new()
    col = Col.new(:next_actor => done, :next_method => :done)
    a = Setter.new(:attr => :a, :forward => col)
    b = Setter.new(:attr => :b, :forward => col)
    c = Setter.new(:attr => :c, :forward => col)
    fan = Fan.new(:fans => [a, b, c])
    job = NotJob.new()
    fan.ask(:go, job)
    ::Opee::Env.wait_close()
    assert_equal(true, done.finished)
    assert_equal(0, col.cache_size)
    assert_equal([true], job.a)
    assert_equal([true], job.b)
    assert_equal([true], job.c)
  end

  def test_opee_job
    done = Done.new()
    col = ::Opee::Collector.new()
    a = Setter.new(:attr => :a, :forward => col)
    b = Setter.new(:attr => :b, :forward => col)
    c = Setter.new(:attr => :c, :forward => col)
    fan = Fan.new(:fans => [a, b, c])
    job = NiceJob.new(done)
    fan.ask(:go, job)
    ::Opee::Env.wait_close()
    assert_equal(true, done.finished)
    assert_equal(0, col.cache_size)
    assert_equal([true], job.a)
    assert_equal([true], job.b)
    assert_equal([true], job.c)
  end

end # OpeeTest
