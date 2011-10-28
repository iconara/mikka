# encoding: utf-8

require 'java'
require 'akka-actor-jars'
require 'akka-remote-jars'


module Akka
  import 'akka.actor.Actors'
  
  module Actor
    include_package 'akka.actor'

    import 'akka.actor.ActorRef'
    import 'akka.actor.UntypedActor'
    import 'akka.actor.Scheduler'

    class UntypedActor
      def self.create(*args)
        new(*args)
      end
    end
  end
  
  module Config
    include_package 'akka.config'
  end
  
  module Routing
    include_package 'akka.routing'
  end
end
