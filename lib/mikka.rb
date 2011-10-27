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
    extend self
    
    def broadcast(message)
      Akka::Routing::Routing::Broadcast.new(message)
    end
  
    def poison_pill
      Akka::Actor::Actors.poison_pill
    end
  end
  
  module Remote
    extend self
    
    DEFAULT_HOST = 'localhost'
    DEFAULT_PORT = 2552
    
    def start(options=nil)
      if options
      then remote_support.start(options.fetch(:host, DEFAULT_HOST), options.fetch(:port, DEFAULT_PORT))
      else remote_support.start
      end
    end
    
    def actor_for(id, options={})
      remote_support.actor_for(id, options.fetch(:host, DEFAULT_HOST), options.fetch(:port, DEFAULT_PORT))
    end
    
  private

    def remote_support
      Akka::Actors.remote
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
    def onReceive(*args)
      capture_current_actor { super }
    end
    
    def preStart(*args)
      capture_current_actor { super }
    end
    
    def postStop(*args)
      capture_current_actor { super }
    end
    
    def preRestart(*args)
      capture_current_actor { super }
    end
    
    def postRestart(*args)
      capture_current_actor { super }
    end
    
  private
    
    def capture_current_actor
      Thread.current[:mikka_current_actor] = context
      yield
    ensure
      Thread.current[:mikka_current_actor] = nil
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
        @life_cycle = begin
          case type
          when :permanent then Akka::Config::Supervision.permanent
          when :temporary then Akka::Config::Supervision.temporary
          when :undefined then Akka::Config::Supervision.undefined_life_cycle
          else raise ArgumentError, 'type must be one of :permanent, :temporary or :undefined'
          end
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
  
  def self.schedule(receiver_actor, message_to_be_sent, initial_delay_before_sending, delay_between_messages, time_unit=TimeUnit::SECONDS)
    Akka::Actor::Scheduler.schedule(receiver_actor, message_to_be_sent, initial_delay_before_sending, delay_between_messages, time_unit)
  end
  
  def self.schedule_once(receiver_actor, message_to_be_sent, delay_until_send, time_unit=TimeUnit::SECONDS)
    Akka::Actor::Scheduler.schedule_once(receiver_actor, message_to_be_sent, delay_until_send, time_unit)
  end
  
  class TimeUnit
    import java.util.concurrent.TimeUnit
    
    DAY         = DAYS         = TimeUnit::DAYS
    HOUR        = HOURS        = TimeUnit::HOURS
    MICROSECOND = MICROSECONDS = TimeUnit::MICROSECONDS
    MILLISECOND = MILLISECONDS = TimeUnit::MILLISECONDS
    MINUTE      = MINUTES      = TimeUnit::MINUTES
    NANOSECOND  = NANOSECONDS  = TimeUnit::NANOSECONDS
    SECOND      = SECONDS      = TimeUnit::SECONDS
  end
end

module Akka
  module Actor
    module ActorRef
      def <<(message)
        tell(message, Mikka.current_actor)
      end
    end
  end
end