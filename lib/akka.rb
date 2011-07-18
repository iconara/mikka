# encoding: utf-8

require 'java'

$AKKA_HOME = File.expand_path('../ext/akka-actors-1.1.2', __FILE__)
$AKKA_LIB_HOME = "#{$AKKA_HOME}/lib"
$AKKA_CONFIG_HOME = "#{$AKKA_HOME}/config"
$CLASSPATH << $AKKA_CONFIG_HOME

require "#{$AKKA_LIB_HOME}/scala-library.jar"
require "#{$AKKA_LIB_HOME}/akka/akka-actor-1.1.2"

require 'ext/scala'


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
