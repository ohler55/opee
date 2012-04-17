
module Opee
  

  class Actor

    def initialize()
      # TBD create thread and queue with mutex
    end

    # deep copy and freeze args if not already frozen or primitive types
    def ask(op, *args)
      args.each do |a|
        puts "*** a: #{a}  frozen? #{a.frozen?}"
      end
      # TBD put on queue
    end

    private

    def act(op, *args)
    end

  end # Actor
end # Opee
