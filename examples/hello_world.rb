# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'mikka'

# 0.
# The numbers at the top of the comment blocks follow the flow of the 
# application, read them in order to see the sequence of events.

# 1.
# The simplest way to create an actor is to do it with a block. The block
# will receive each message and execute in the scope of an actor object (so
# `context` will be available -- more on that later).
#
# The variable `phil` will not refer directly to an actor instance, but to an
# `ActorRef`. There are many reasons for this, and for the full picture refer
# to the Akka documentation. The short explanation is that it makes it 
# possible to restart and replace the actor without the clients knowing that
# the actor instance was changed, and it makes remote actors transparent.
phil = Mikka.actor do |msg|
  # 8. 
  # Ruby doesn't have pattern matching, but `case` is usually enough. If you
  # Have separate classes for your messages you can match on class.
  case msg
  when Introduction
    # 9.
    # The `Introduction` class has a field called `to_whom` that contains a
    # reference to an actor that someone want to introduce us to. Let's send
    # that actor a `Greeting`. 
    # 
    # Instead of using the << operator to send a message, here we use the more
    # explict #send_one_way, because we want to pass the sender (i.e. ourself)
    # so that the receiver can reply. This is much more elegant in Scala,
    # where the sender is implicitly inferred at the time of the call. In Ruby
    # (and in Java) we need to remember to pass the sender along manually.
    #
    # The second argument to #send_one_way is the sender, i.e. this actor, or
    # rather the `ActorRef` that fronts this actor. In Scala it would be 
    # referred to as `self`, but in the Java API it's called `context` (which
    # is good news for us Rubyists).
    msg.to_whom.send_one_way(Greeting.new('Hello, dear sir.'), context)
  when Greeting
    puts "Received greeting: #{msg.body}"
    # 12.
    # The reply got routed back to this actor. Now we want to shut down this
    # actor too, so that the application can shut down.
    context.exit
  end
end

# 2.
# If you need more control over your actor's life cycle, or want to create
# more than one of the same you can can declare a subclass of Mikka::Actor.
# The #receive method is called for each message the actor receives. You can
# do things when the actor starts by implementing #pre_start, and when the 
# actor stops by implementing #post_stop.
#
# Don't create instances of this class yourself, an error will be raised if
# it's done in the wrong way, see below for how it's supposed to be done.
class Replier < Mikka::Actor
  def receive(msg)
    case msg
    when Greeting
      puts "Received greeting: #{msg.body}"
      # 10.
      # Since this message had a sender (see 9) we can use #reply to send a
      # message back without having an explicit reference to the actor that
      # sent the message (if you, however, want to store the sender and reply
      # later you can retrieve it using `context.sender.get` and then use <<
      # or #send_one_way to send a message to it, that is basically what 
      # #reply does).
      #
      # A word of caution: since the sender has to be explicitly passed when
      # sending the message it is not advisable to assume that the sender will
      # always be set. You can use #reply_safe to avoid errors being raised
      # (it will return true or false depending on whether it could send the
      # reply or not).
      context.reply(Greeting.new('Why, hello old chap.'))
      # 11.
      # Now we're through with this actor, so we shut it down.
      context.exit
    end
  end
end

# 3.
# This is how you create an actor reference from a subclass of Mikka::Actor.
# Creating the instance this way makes sure that the actor is set up correctly
# (refer to the Akka documentation as to why it works this way).
sam = Mikka.actor_of(Replier)

# 4.
# Messages can be anything, but if your messages are more complex than a 
# simple string or symbol you are best off declaring a proper class to 
# encapsulate them. `Struct` is convenient in this case (but creates mutable
# objects, consider using the `immutable_struct` gem instead).
class Introduction < Struct.new(:to_whom); end
class Greeting < Struct.new(:body); end

# 5.
# An actor must be started before it can be used!
phil.start
sam.start

# 6.
# And finally, this is how to send a message to an actor. In Erlang and Scala
# it is done with !, but that operator is not overridable in Ruby, so we have
# to make do with <<. The Akka Java API defines #send_one_way (actually
# sendOneWay, but JRuby fixes the casing for us), which can also be used (and
# must be used if you want to be able to reply to messages).
#
# Here we send a message to `phil`, the message is an object that contains a
# reference to the actor `sam`.
phil << Introduction.new(sam)

# 7.
# The application will keep running until the last actor is dead. If you want
# to force shutdown you can use `Mikka.registry.shutdown_all`.