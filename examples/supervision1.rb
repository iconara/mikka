# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'mikka'


class Worker < Mikka::Actor
  life_cycle :permanent
  
  def pre_start
    puts "#{context.id} starting"
  end
  
  def pre_restart(reason)
    puts "#{context.id} restarting"
  end
  
  def post_restart(reason)
    puts "#{context.id} restarted"
  end
  
  def post_stop
    puts "#{context.id} stopped"
  end
  
  def receive(message)
    raise java.lang.Exception.new('Oh, shucks') if message == 'hard work'
    puts "#{context.id} Work on #{message}"
  end
end

class Manager < Mikka::Actor
  fault_handling :strategy => :all_for_one, :trap => [java.lang.Exception], :max_retries => 3, :time_range => 3000
  
  def pre_start
    @worker1 = Mikka.actor_of(Worker)
    @worker2 = Mikka.actor_of(Worker)
    @worker1.id = 'worker1'
    @worker2.id = 'worker2'
    context.start_link(@worker1)
    context.start_link(@worker2)
    @worker1 << 'simple work'
    @worker2 << 'hard work'
    @worker2 << 'simple work'
    @worker2 << 'simple work'
    @worker2 << 'hard work'
    @worker2 << 'simple work'
    @worker2 << 'simple work'
    @worker2 << 'simple work'
  end
end

manager = Mikka.actor_of(Manager).start