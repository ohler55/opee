
require 'opee'

class Relay < ::Opee::Actor
  attr_reader :last_data
  attr_reader :buddy

  def initialize(options={})
    @buddy = nil
    @last_data = nil
    super(options)
  end
  
  def set_options(options)
    @buddy = options[:buddy]
  end

  private

  def relay(data)
    @last_data = data
    @buddy.ask(:relay, data) unless @buddy.nil?
  end

end # Relay
