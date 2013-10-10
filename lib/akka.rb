# encoding: utf-8

require 'java'
require 'typesafe-config-jars'
require 'akka-actor-jars'

module Akka
  module Actor
    java_import 'akka.actor.ActorSystem'
    java_import 'akka.actor.ActorRef'
    java_import 'akka.actor.UntypedActor'
    java_import 'akka.actor.Props'
    java_import 'akka.actor.Terminated'
    java_import 'akka.actor.AllForOneStrategy'
    java_import 'akka.actor.OneForOneStrategy'   
    java_import 'akka.actor.SupervisorStrategy'        
  end

  module Japi
    java_import 'akka.japi.Function'
  end

  module Dispatch
    java_import 'scala.concurrent.Await'
  end

  module Util
    java_import 'scala.concurrent.duration.Duration'
    java_import 'akka.util.Timeout'
  end
end
