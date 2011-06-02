# encoding: utf-8

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
