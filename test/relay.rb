
require 'opee'

class Relay < ::Opee::Actor
  attr_reader :last_data

  def initialize(buddy)
    super
    @buddy = buddy
    @last_data = nil
  end
  
  private

  def relay(data)
    @last_data = data
    @buddy.ask(:relay, data) unless @buddy.nil?
  end

end # Relay
