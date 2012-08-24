# encoding: utf-8

require 'akka'


module Mikka
  def self.create_actor_system(*args)
    Akka::Actor::ActorSystem.create(*args)
  end

  def self.await_result(future, options={})
    Akka::Dispatch::Await.result(future, Duration[options[:timeout]])
  end
  
  def self.current_actor=(actor)
    Thread.current[:mikka_current_actor] = actor
  end
  
  def self.current_actor
    Thread.current[:mikka_current_actor]
  end
  
  def self.capture_current_actor(ref)
    self.current_actor = ref
    yield
  ensure
    self.current_actor = nil
  end
  
  ActorRef = Akka::Actor::ActorRef
  Props = Akka::Actor::Props
  Duration = Akka::Util::Duration
  Timeout = Akka::Util::Timeout
  Terminated = Akka::Actor::Terminated

  class Props
    def self.[](*args, &block)
      options = args.last.is_a?(Hash) && args.pop
      creator = ((args.first.is_a?(Proc) || args.first.is_a?(Class)) && args.first) || (options && options[:creator]) || block
      raise ArgumentError, %(No creator specified) unless creator
      props = new
      props = props.with_creator(creator)
      props
    end

    class << self
      alias_method :create, :[]
    end
  end

  class Duration
    def self.[](*args)
      Akka::Util::Duration.apply(*args)
    end
  end

  class ActorRef
    def <<(msg)
      tell(msg, Mikka.current_actor)
    end
  end

  module RubyesqueActorCallbacks
    def receive(message); end
    def pre_start; end
    def post_stop; end
    def pre_restart(reason, message); end
    def post_restart(reason); end

    def onReceive(message); receive(message); end
    def preStart; super; pre_start; end
    def postStop; super; post_stop; end
    def preRestart(reason, message_option) 
      super 
      pre_restart(reason, message_option.is_defined ? message_option.get : nil)
    end
    def postRestart(reason); super; post_restart(reason); end
  end

  module ImplicitSender
    def onReceive(*args)
      Mikka.capture_current_actor(get_self) { super }
    end
    
    def preStart(*args)
      Mikka.capture_current_actor(get_self) { super }
    end
    
    def postStop(*args)
      Mikka.capture_current_actor(get_self) { super }
    end
    
    def preRestart(*args)
      Mikka.capture_current_actor(get_self) { super }
    end
    
    def postRestart(*args)
      Mikka.capture_current_actor(get_self) { super }
    end    
  end

  class Actor < Akka::Actor::UntypedActor
    include RubyesqueActorCallbacks
    include ImplicitSender
    
    class << self
      alias_method :apply, :new
      alias_method :create, :new
    end
  end

  module PropsConstructor
    def Props(&block)
      Props.create(&block)
    end
  end
  
  module Useful
    include PropsConstructor
    extend PropsConstructor

    Props = ::Mikka::Props
  end
end

