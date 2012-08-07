# encoding: utf-8

require 'java'
require 'akka-actor-jars'


module Akka
  module Actor
    java_import 'akka.actor.ActorSystem'
    java_import 'akka.actor.ActorRef'
    java_import 'akka.actor.UntypedActor'
    java_import 'akka.actor.Props'
    java_import 'akka.actor.Terminated'
  end

  module Dispatch
    java_import 'akka.dispatch.Await'
  end

  module Util
    java_import 'akka.util.Duration'
    java_import 'akka.util.Timeout'
  end
end
