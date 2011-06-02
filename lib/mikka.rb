# encoding: utf-8

require 'java'
require 'akka'


module Mikka
  def self.actor_of(*args)
    if block_given?
    then Akka::Actor::Actors.actor_of { ProcActor.new(&Proc.new) }
    else Akka::Actor::Actors.actor_of(*args)
    end
  end
  
  class Actor < Akka::Actor::UntypedActor
    def onReceive(message); receive(message); end
    def preStart; pre_start; end
    def postStop; post_stop; end
    def preRestart(reason); pre_restart(reason); end
    def postRestart(reason); post_restart(reason); end

    def receive(message)
    end

    def pre_start
    end

    def post_stop
    end

    def pre_restart(reason)
    end

    def post_restart(reason)
    end
  end
  
  class ProcActor < Actor
    def initialize(&receive)
      define_singleton_method(:receive, receive)
    end
  end
end
