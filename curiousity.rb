curiosity
#kills
#your cat
 
class Object
  def +@(&block)
    if block
      each(&block)
    else
      lambda{|blk| this.each(blk) }
    end
  end
  def %(args)
    send *args 
  end
  def -@(&block)
    if block
      reverse_each(&block)
    else
      lambda{|blk| reverse_each(blk) }
    end
  end
  
  def <(x, &block)
    if block
      inject(x, &block)
    else
      lambda{|blk| inject(x, blk) }
    end
  end
  
  def ~(&block)
    if block
      map(&block)
    else
      lambda{|blk| map(blk) }
    end
  end
 
 
end
 
class Range
  def reverse_each(&block)
    last.downto(first,&block)
  end
end
 
 
module MethodMissingMatch
    def method_missing(sym, *args)
        self.class.missing.each{|k, v|
            if k=~sym.to_s
              return v.call(sym, *args)
            end
        }
    end
end
  
class MethodChain
  def initialize(str)
    @str = str
  end
  def str
    @str
  end
  def method_missing(*args)
    (@arr ||= []).push(args)
    self
  end
    
  def to_proc
    (@arr ||=[]).unshift([self.str])
    arr = @arr
    ret = lambda{|x| arr.inject(x){|y,z|y.send *z}}
    @arr = []
    ret 
  end
end
class Symbol
  def -@
    $__symbol__ = self
  end
  def ~@
    $__klass__  = eval ("
      class ::#{self.to_s}; 
        def self.missing
          @@missing ||= {}
        end
        include MethodMissingMatch; 
        self; 
      end;")
  end
  def klass
    self.~@
  end
  def <(obj)
    "#{self} < #{obj}".to_sym
  end
  def module
    $__klass__  = eval ("module ::#{self.to_s}; self; end;")
  end
  
  def method_missing(*args)
    MethodChain.new(to_s).send(*args)
  end  
  
  def to_a
    [self]
  end
end
 
class Proc
  def -@
    proc = self
    (class<<$__klass__;self;end).class_eval{
        send :define_method, $__symbol__, &proc
    }
  end
  def +@
    proc = self
    $__klass__.class_eval{
        send :define_method, $__symbol__, &proc
    }
  end
  def ~@
    $__klass__.class_eval(&self)
  end
end
 
class Module
  def -@
    $__klass__.send :extend, self
  end
  def +@
    $__klass__.send :include, self
  end
end
 
class Regexp
  def -@(&proc)
    $__klass__.missing[self]=proc
  end
  def %(arg)
    str = arg.shift
    arg.map{|x| str[self, x]}
  end
end
 
class String
  def /(reg) 
    reg.is_a?(Regexp) ? 
        split(reg)  :     # the inverse of Array#join
        self + "/" + reg  # PathAppend "C:" / "windows" => "C:/windows"
      end
  
end
 
class Hash
  def +@
    x = keys
    Struct.new(*x).new(*x.map{|y|self[y]})
  end
end
 
class Struct
  def -@
    x = {}
    members.each{|mem|
        x[mem] = send mem
    }
    x
  end
end
 
class Class
  def %(arg, &block)
    ret = new(*arg)
    if block
      ret.instance_eval(block)
    else
      ret
    end
  end
end
 
 
class Array
  def to_proc
    prc = map{|pr| pr.to_proc}
    lambda{|*args|
      prc.map{|pr| pr.call(*args)}
    }
  end
end
def `(arg) #` 
    $__klass__.class_eval(arg)
end
 
:Test.module
  -:add
  + ->a{
        @a+=a
  }
  
  -:talk_ancestors 
  - ->{
    p ancestors
  }
  
 
 
~ (:MyMath < IO)
  +Test        #include Test
  -Test        #extend Test
  `p instance_methods`     #class_eval(module_eval) text
    
  -:initialize
    + ->a{
      @a = a
    }
  -:sub
    + ->a{
        @a -= a
      }
  -:value
    + ->{
        @a
      }
  -:dbl
    - ->*arg{
        arg.~ {|x|
          x*2
        }
      }
  /a./.-@ {|*args| #method_missing sym matching /a./
      p args
  }
 
~:Stat
  -:sum
    - ->*arg{
        arg.<(0){|a,b|
            a+b
        }
    }
 
      
x = MyMath % [5] 
x % [:add, 4]
x % [:sub, 5]
p x % :value
p /(.)(.)(.)/ % ["abc", 1,2,3]
p "a,b,c" / ","
p -+{ :name=>1, :path=>2} #=> Should almost be the same hash
p [1,2,3,4,5].map &([:to_s*3, :to_s*1, :to_s*2, [:to_s*4, :to_f**2] ])
