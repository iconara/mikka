# encoding: utf-8

require 'java'
require 'akka'


module Mikka
  def self.actor_of(*args, &block)
    Akka::Actor::Actors.actor_of(*args, &block)
  end
  
  def self.actor(&block)
    Akka::Actor::Actors.actor_of { ProcActor.new(&block) }
  end
  
  def self.registry
    Akka::Actor::Actors.registry
  end

  class Actor < Akka::Actor::UntypedActor
    def receive(message); end
    def pre_start; end
    def post_stop; end
    def pre_restart(reason); end
    def post_restart(reason); end
    
    def onReceive(message); receive(message); end
    def preStart; super; pre_start; end
    def postStop; super; post_stop; end
    def preRestart(reason); super; pre_restart(reason); end
    def postRestart(reason); super; post_restart(reason); end
  end
  
  class ProcActor < Actor
    def initialize(&receive)
      define_singleton_method(:receive, receive)
    end
  end
end
