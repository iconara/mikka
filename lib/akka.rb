# encoding: utf-8

require 'java'
require 'akka-actor-jars'


module Akka
  module Actor
    include_package 'akka.actor'

    import 'akka.actor.ActorRef'
    import 'akka.actor.UntypedActor'

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
