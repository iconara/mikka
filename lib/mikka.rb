# encoding: utf-8

require 'java'
require 'akka'


module Mikka
  import java.util.Arrays
  
  def self.actor_of(*args, &block)
    Akka::Actor::Actors.actor_of(*args, &block)
  end
  
  def self.actor(&block)
    Akka::Actor::Actors.actor_of { ProcActor.new(&block) }
  end
  
  def self.registry
    Akka::Actor::Actors.registry
  end
  
  def self.current_actor
    Thread.current[:mikka_current_actor]
  end
  
  module Messages
    def self.broadcast(message)
      Akka::Routing::Routing::Broadcast.new(message)
    end
  
    def self.poison_pill
      Akka::Actor::Actors.poison_pill
    end
  end
  
  module Remote
    def self.start(options={})
      raise ArgumentError, %(No port given) unless options.key?(:port)
      Akka::Actors.remote.start(options.fetch(:host, 'localhost'), options[:port])
    end
    
    def self.actor_for(id, options={})
      raise ArgumentError, %(No port given) unless options.key?(:port)
      Akka::Actors.remote.actor_for(id, options.fetch(:host, 'localhost'), options[:port])
    end
  end
  
  module RubyesqueActorCallbacks
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
  
  module ImplicitSender
    def capture_current_actor
      Thread.current[:mikka_current_actor] = context
      yield
    ensure
      Thread.current[:mikka_current_actor] = nil
    end
    
    def self.included(mod)
      mod.class_eval do
        [:onReceive, :preStart, :postStop, :preRestart, :postRestart].each do |method_name|
          actual_method_name = :"__actual_#{method_name}"
          alias_method actual_method_name, method_name
          define_method method_name do |*args|
            capture_current_actor do
              send(actual_method_name, *args)
            end
          end
        end
      end
    end
  end
  
  module SupervisionDsl
    module ClassMethods
      def fault_handling(config)
        trap = config[:trap].map { |e| e.java_class }
        max_retries = config.fetch(:max_retries, 5)
        time_range = config.fetch(:time_range, 5000)
        case config[:strategy]
        when :all_for_one
          @fault_handling_strategy = Akka::Config::Supervision::AllForOneStrategy.new(trap, max_retries, time_range)
        when :one_for_one
          @fault_handling_strategy = Akka::Config::Supervision::OneForOneStrategy.new(trap, max_retries, time_range)
        else
          raise ArgumentError, 'strategy must be one of :all_for_one or :one_for_one'
        end
      end
    
      def registered_fault_handling_strategy
        @fault_handling_strategy
      end
    
      def life_cycle(type)
        @life_cycle = case type
                      when :permanent then Akka::Config::Supervision.permanent
                      when :temporary then Akka::Config::Supervision.temporary
                      when :undefined then Akka::Config::Supervision.undefined_life_cycle
                      else raise ArgumentError, 'type must be one of :permanent, :temporary or :undefined'
                      end
      end
    
      def registered_life_cycle
        @life_cycle
      end
    end
    
    module InstanceMethods
      def initialize(*args)
        super
        if self.class.registered_fault_handling_strategy
          context.fault_handler = self.class.registered_fault_handling_strategy
        end
        if self.class.registered_life_cycle
          context.life_cycle = self.class.registered_life_cycle
        end
      end
    end
    
    def self.included(m)
      m.extend(ClassMethods)
      m.include(InstanceMethods)
    end
  end
  
  class Actor < Akka::Actor::UntypedActor
    include SupervisionDsl
    include RubyesqueActorCallbacks
    include ImplicitSender
  end
  
  class ProcActor < Actor
    def initialize(&receive)
      define_singleton_method(:receive, receive)
    end
  end
  
  def self.load_balancer(options={})
    actors = options[:actors]
    unless actors
      type = options[:type]
      count = options[:count]
      raise ArgumentError, "Either :actors or :type and :count must be specified" unless type && count
      actors = (0...count).map { actor_of(type) }
    end
    actors.each { |a| a.start }
    actor_list = Arrays.as_list(actors.to_java)
    actor_seq = Akka::Routing::CyclicIterator.new(actor_list)
    actor_factory = proc { actor_seq }.to_function
    Akka::Routing::Routing.load_balancer_actor(actor_factory)
  end
end

module Akka
  module Actor
    module ActorRef
      def <<(message)
        send_one_way(message, Mikka.current_actor)
      end
    end
  end
end