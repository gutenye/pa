require "rbconfig"

class Pa
  # In order to reduce the dependencies, this Util class contains some util functions.
  class Util
    module Concern
      def included(base)
        base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
      end
    end

    class << self
      # Extracts options from a set of arguments. 
      #
      # @example
      #
      #   dirs, o = Util.extract_options(["foo", "bar", {a: 1}], b: 2)  
      #     -> ["foo", "bar"], {a: 1, b: 2}
      #
      #   (dir,) o = Util.extract_options(["foo", {a: 1}])
      #     -> "foo", {a: 1}
      #
      # @return [Array<Array,Hash>] 
      def extract_options(args, default={})
        if args.last.instance_of?(Hash)
          [args[0...-1], default.merge(args[-1])]
        else
          [args, default]
        end
      end

      # Wraps its argument in an array unless it is already an array (or array-like).
      #
      # Specifically:
      #
      # * If the argument is +nil+ an empty list is returned.
      # * Otherwise, if the argument responds to +to_ary+ it is invoked, and its result returned.
      # * Otherwise, returns an array with the argument as its single element.
      #
      #   Array.wrap(nil)       # => []
      #   Array.wrap([1, 2, 3]) # => [1, 2, 3]
      #   Array.wrap(0)         # => [0]
      #
      # This method is similar in purpose to <tt>Kernel#Array</tt>, but there are some differences:
      #
      # * If the argument responds to +to_ary+ the method is invoked. <tt>Kernel#Array</tt>
      # moves on to try +to_a+ if the returned value is +nil+, but <tt>Array.wrap</tt> returns
      # such a +nil+ right away.
      # * If the returned value from +to_ary+ is neither +nil+ nor an +Array+ object, <tt>Kernel#Array</tt>
      # raises an exception, while <tt>Array.wrap</tt> does not, it just returns the value.
      # * It does not call +to_a+ on the argument, though special-cases +nil+ to return an empty array.
      #
      # The last point is particularly worth comparing for some enumerables:
      #
      #   Array(:foo => :bar)      # => [[:foo, :bar]]
      #   Array.wrap(:foo => :bar) # => [{:foo => :bar}]
      #
      #   Array("foo\nbar")        # => ["foo\n", "bar"], in Ruby 1.8
      #   Array.wrap("foo\nbar")   # => ["foo\nbar"]
      #
      # There's also a related idiom that uses the splat operator:
      #
      #   [*object]
      #
      # which returns <tt>[nil]</tt> for +nil+, and calls to <tt>Array(object)</tt> otherwise.
      #
      # Thus, in this case the behavior is different for +nil+, and the differences with
      # <tt>Kernel#Array</tt> explained above apply to the rest of +object+s.
      def wrap_array(object)
        if object.nil?
          []
        elsif object.respond_to?(:to_ary)
          object.to_ary || [object]
        else
          [object]
        end
      end

      # Slice a hash to include only the given keys. This is useful for
      # limiting an options hash to valid keys before passing to a method:
      #
      # @example
      #
      #    a = {a: 1, b: 2, c: 3}
      #    a.slaice(:a, :b)                -> {a: 1, b: 2}
      def slice(hash, *keys)
        keys = keys.map! { |key| hash.convert_key(key) } if hash.respond_to?(:convert_key)
        h = hash.class.new
        keys.each { |k| h[k] = hash[k] if hash.has_key?(k) }
        h
      end

      # different to File.join. 
      #
      # @example
      #
      #   join_path(".", "foo")  -> "foo" not "./foo"
      #
      def join_path(dir, *names)
        dir == "." ? File.join(*names) : File.join(dir, *names)
      end

      def linux?
        RbConfig::CONFIG["host_os"] =~ /linux|cygwin/
      end

      def mac?
        RbConfig::CONFIG["host_os"] =~ /mac|darwin/
      end

      def bsd?
        RbConfig::CONFIG["host_os"] =~ /bsd/
      end

      def windows?
        RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
      end

      def solaris?
        RbConfig::CONFIG["host_os"] =~ /solaris|sunos/
      end

      # TODO: who knows what symbian returns?
      def symbian?
        RbConfig::CONFIG["host_os"] =~ /symbian/
      end

      def posix?
        linux? or mac? or bsd? or solaris? or begin 
          fork do end
          true
        rescue NotImplementedError, NoMethodError
          false
        end
      end
    end
  end
end
