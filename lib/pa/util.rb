class Pa
  class Util
    module Concern
      def included(base)
        base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
        base.send :include, const_get(:InstanceMethods) if const_defined?(:InstanceMethods)
      end
    end

    class << self
      # extract options
      # @see extract_options!
      # @example
      #   def mkdir(*args)
      #     paths, o = args.extract_options
      #   end
      #
      # @return [Array<Array,Hash>] 
      def extract_options(ary, default={})
        if ary.last.is_a?(Hash) && ary.last.instance_of?(Hash)
          [ary[0...-1], ary[-1].merge(default)]
        else
          [ary, default]
        end
      end

      def wrap_array(value)
        Array === value ? value : [value]
      end
    end
  end
end
