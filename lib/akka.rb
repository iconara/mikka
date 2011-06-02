# encoding: utf-8

$AKKA_HOME = File.expand_path('../ext/akka-actors-1.1.2', __FILE__)
$CLASSPATH << "#{$AKKA_HOME}/config"

require "#{$AKKA_HOME}/lib/scala-library.jar"
require "#{$AKKA_HOME}/lib/akka/akka-actor-1.1.2"


module Akka
  module Actor
    include_package 'akka.actor'
    
    import 'akka.actor.ActorRef'
    import 'akka.actor.UntypedActor'

    module ActorRef
      def <<(message)
        send_one_way(message)
      end
    end

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
