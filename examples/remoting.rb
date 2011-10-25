$: << File.expand_path('../../lib', __FILE__)

# Run this with the argument 'server' to start a server, then run again 
# without argument to run a client

require 'mikka'


SERVICE_NAME = 'translation-service'
SERVER_PORT = 1337


if ARGV.any? && ARGV.first == 'server'
  # this is the server, it spawns the actor, starts a server and registers the 
  # actor with the server

  class ServerActor < Mikka::Actor
    TRANSLATIONS = {
      'bonjour' => 'hello'
    }
    
    def receive(message)
      context.reply_safe(TRANSLATIONS[message])
    end
  end

  # start the server, the host can be specified with :host and defaults to
  # localhost (the port defaults to 2552, but 1337 is cooler)
  server = Mikka::Remote.start(:port => SERVER_PORT)

  # create and register an actor with the server, this ID is used by the 
  # client to get a reference to the actor
  server.register(SERVICE_NAME, Mikka.actor_of(ServerActor))
  
  # now we're just waiting for messages
else
  # this is the client code, it connects to the remote actor and sends it a message
  
  class ClientActor < Mikka::Actor
    def initialize(word)
      super() # remember to use super with parentheses!
      @word = word
    end
    
    def pre_start
      # this gets an actor reference to the remote actor, you need to supply
      # the ID the actor was registered with, and the host and port where it's
      # running (these default to localhost and 2552)
      @translation_actor = Mikka::Remote.actor_for(SERVICE_NAME, :port => SERVER_PORT)
      @translation_actor << @word
    end
    
    def receive(message)
      if message
        puts "#{@word} means #{message}"
      else
        puts "#{@word} has no meaning"
      end
      context.exit
    end
  end
  
  # if you want to receive replies you need to start a server on the client 
  # side too, but you can use the no-args constructor to use the defaults
  # (just don't use the defaults for both server and client)
  Mikka::Remote.start
  
  client = Mikka.actor_of { ClientActor.new('bonjour') }
  client.start
end