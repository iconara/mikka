# encoding: utf-8

require 'set'


class Proc
  ARITY_MAP = [
    Java::Scala::Function0,
    Java::Scala::Function1,
    Java::Scala::Function2,
    Java::Scala::Function3,
    Java::Scala::Function4
  ]
  
  def to_function
    f = ARITY_MAP[arity].new
    f.define_singleton_method(:apply, self)
    f
  end
end

$make_java_package_module = proc do |name|
  Module.new do
    include_package name.downcase
    
    define_singleton_method :const_missing do |const|
      begin
        java_class = JavaUtilities.get_java_class("#{name.downcase}.#{const}")
        proxy_class = JavaUtilities.create_proxy_class(const, java_class, self)
        proxy_class
      rescue => e
        const_set(const, $make_java_package_module.call("#{name.downcase}.#{const.downcase}"))
      end
    end
  end
end

Scala = $make_java_package_module.call(:Scala)

# The following is from:
# http://www.codecommit.com/blog/ruby/integrating-scala-into-jruby
# http://www.codecommit.com/blog/misc/scala.rb

OPERATORS = {
  '=' => '$eq', 
  '>' => '$greater', 
  '<' => '$less',
  '+' => '$plus',
  '-' => '$minus',
  '*' => '$times',
  '/' => 'div',
  '!' => '$bang',
  '@' => '$at',
  '#' => '$hash',
  '%' => '$percent',
  '^' => '$up',
  '&' => '$amp',
  '~' => '$tilde',
  '?' => '$qmark',
  '|' => '$bar',
  "\\" => '$bslash'
}

module OperatorRewrites
  @__operator_rewrites_included__ = true
  
  alias_method :__old_method_missing_in_scala_rb__, :method_missing
  def method_missing(sym, *args)
    str = sym.to_s
    str = $&[1] + '_=' if str =~ /^(.*[^\]=])=$/
    
    OPERATORS.each { |from, to| str.gsub!(from, to) }

    gen_with_args = proc do |name, args|
      code = "#{name}("
      unless args.empty?
        for i in 0..(args.size - 2)
          code += "args[#{i}], "
        end
        code += "args[#{args.size - 1}]"
      end
      code += ')'
    end
    
    if str == '[]'
      eval(gen_with_args.call('apply', args))
    elsif sym.to_s == '[]='
      eval gen_with_args.call('update', args)            # doesn't work right
    elsif sym == :call and type_of_scala_function self
      eval(gen_with_args.call('apply', args))
    elsif sym == :arity and (ar = type_of_scala_function self) != nil
      ar
    elsif sym == :binding and type_of_scala_function self
      binding
    elsif sym == :to_proc and type_of_scala_function self
      self
    elsif methods.include? str
      send(str.to_sym, args)
    else
      __old_method_missing_in_scala_rb__(sym, args)
    end
  end

private

  def type_of_scala_function(obj)
    if    obj.java_kind_of? Scala::Function0  then 0
    elsif obj.java_kind_of? Scala::Function1  then 1
    elsif obj.java_kind_of? Scala::Function2  then 2
    elsif obj.java_kind_of? Scala::Function3  then 3
    elsif obj.java_kind_of? Scala::Function4  then 4
    elsif obj.java_kind_of? Scala::Function5  then 5
    elsif obj.java_kind_of? Scala::Function6  then 6
    elsif obj.java_kind_of? Scala::Function7  then 7
    elsif obj.java_kind_of? Scala::Function8  then 8
    elsif obj.java_kind_of? Scala::Function9  then 9
    elsif obj.java_kind_of? Scala::Function10 then 10
    elsif obj.java_kind_of? Scala::Function11 then 11
    elsif obj.java_kind_of? Scala::Function12 then 12
    elsif obj.java_kind_of? Scala::Function13 then 13
    elsif obj.java_kind_of? Scala::Function14 then 14
    elsif obj.java_kind_of? Scala::Function15 then 15
    elsif obj.java_kind_of? Scala::Function16 then 16
    elsif obj.java_kind_of? Scala::Function17 then 17
    elsif obj.java_kind_of? Scala::Function18 then 18
    elsif obj.java_kind_of? Scala::Function19 then 19
    elsif obj.java_kind_of? Scala::Function20 then 20
    elsif obj.java_kind_of? Scala::Function21 then 21
    elsif obj.java_kind_of? Scala::Function22 then 22
    else nil
    end
  end
end

class Java::JavaLang::Object
  include OperatorRewrites
end

class Module
  alias_method :__old_include_in_scala_rb__, :include
  def include(*modules)
    modules.each do |m|
      clazz = nil
      begin
        if m.respond_to?(:java_class) && m.java_class.interface?
          cl = m.java_class.class_loader
          mixin_methods_for_trait(cl, cl.load_class(m.java_class.to_s))
          __old_include_in_scala_rb__(OperatorRewrites) unless @__operator_rewrites_included__
        end
      rescue => e
        puts "*** #{e.message}"
      end
      
      if defined? @@trait_methods
        define_method :scala_reflective_trait_methods do
          @@trait_methods
        end
      end
    end
    
    modules.each {|m| __old_include_in_scala_rb__(m) }
  end
  
  def mixin_methods_for_trait(cl, trait_class, done=Set.new)
    return if done.include?(trait_class)
    done << trait_class
    
    clazz = cl.loadClass("#{trait_class.name}$class")
    
    trait_class.interfaces.each do |i|
      mixin_methods_for_trait(cl, i, done) rescue nil
    end
    
    clazz.declared_methods.each do |meth|
      mod = meth.modifiers
      if java.lang.reflect.Modifier.isStatic(mod) and java.lang.reflect.Modifier.isPublic(mod)
        @@trait_methods ||= []
        unless meth.name.include?('$')
          module_eval <<-CODE
def #{meth.name}(*args, &block)
  args.insert(0, self)
  args << block unless block.nil?
  
  args.map! do |a|
    if defined? a.java_object
      a.java_object
    else
      a
    end
  end
  
  begin
    scala_reflective_trait_methods[#{@@trait_methods.size}].invoke(nil, args.to_java)
  rescue java.lang.reflect.InvocationTargetException => e
    # TODO  change over for 1.1.4
    raise e.cause.message.to_s
  end
end
CODE
          
          @@trait_methods << meth
        else
          define_method meth.name do |*args| # fallback for methods with special names
            args.insert(0, self)
            
            begin
              meth.invoke(nil, args.to_java)
            rescue java.lang.reflectInvocationTargetException => e
              raise e.cause.message.to_s
            end
          end
        end
      end
    end
  end
end

class BoxedRubyArray
  include Scala::Collection::IndexedSeq
  
  def initialize(delegate)
    @delegate = delegate
  end
  
  def apply(i)
    @delegate[i]
  end
  
  def length
    @delegate.size
  end
end

class Array
  def to_scala
    BoxedRubyArray.new self
  end
end

class BoxedRubyHash
  include Scala::Collection::Mutable::Map
  
  def initialize(delegate)
    @delegate = delegate
  end
  
  define_method '$minus$eq' do |e|
    @delegate.delete e
  end
  
  def get(k)
    if @delegate.has_key? k
      Scala::Some.new @delegate[k]
    else
      clazz = Scala::None.java_class.class_loader.loadClass('scala.None$')
      clazz.getField('MODULE$').get nil
    end
  end
  
  def update(k, v)
    @delegate[k] = v
    nil
  end
  
  def elements
    BoxedRubyHashIterator.new @delegate
  end
end

class BoxedRubyHashIterator
  include Scala::Collection::Iterator
  
  def initialize(delegate)
    @delegate = delegate
    @keys = delegate.keys
    @index = 0
  end
  
  def hasNext
    @index < @keys.size
  end
  
  define_method :next do
    back = @delegate[@keys[@index]]
    @index += 1
    
    back
  end
end

class Hash
  def to_scala
    BoxedRubyHash.new self
  end
end