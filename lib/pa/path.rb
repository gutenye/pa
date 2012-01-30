=begin

attribute absolute and dir return String, method absolute_path(), dirname() return Pa
  
  Pa("/home/a").dir #=> "/home"
  Pa("/home/a").dirname #=> Pa("/home")

== methods from String
* +
* [g]sub[!] match =~ 
* start_with? end_with?

=end
class Pa
  module Path
    extend Util::Concern

    module ClassMethods
      DELEGATE_METHODS = [:pwd, :dir, :absolute, :expand, :real, :parent]

      # return current work directory
      # @return [String] path
      def pwd2
        Dir.getwd 
      end

      # is path an absolute path ?
      #
      # @param [String,Pa] path
      # @return [Boolean]
      def absolute?(path) 
        path=get(path) 
        File.absolute_path(path) == path 
      end

      # is path a dangling symlink?
      #
      # a dangling symlink is a dead symlink.
      #
      # @param [String,Pa] path
      # @return [Boolean]
      def dangling? path
        path=get(path)
        if File.symlink?(path)
          src = File.readlink(path)
          not File.exists?(src)
        else
          nil
        end
      end # def dsymlink?

      def dir2(path)
        File.dirname(path)
      end

      # get a basename of a path
      #
      # @example
      #   Pa.basename("foo.bar.c", ext: true)  #=> \["foo.bar", "c"]
      #
      # @param [String,Pa] name
      # @param [Hash] o options
      # @option o [Boolean, String] :ext (false) return \[name, ext] if true
      #   
      # @return [String] basename of a path unless o[:ext]
      # @return [Array<String>] \[name, ext] if o[:ext].  
      def base2(name, o={})
        name = File.basename(get(name))
        if o[:ext]
          name, ext = name.match(/^(.+?)(?:\.([^.]+))?$/).captures
          [ name, (ext || "")]
        else
          name
        end
      end

      def base(*args, &blk)
        rst = base2(*args, &blk)

        if Array===rst
          [ Pa(rst[0]), rst[1] ]
        else
          rst
        end
      end

      # ext of a path
      #
      # @example
      # 	"a.ogg" => "ogg"
      # 	"a" => nil
      #
      # @param [String,Pa] path
      # @return [String]
      def ext2 path
        _, ext = get(path).match(/\.([^.]+)$/).to_a
        ext
      end

      alias ext ext2

      # alias from File.absolute_path
      # @param [String,Pa] path
      # @return [String]
      def absolute2(path) 
        File.absolute_path get(path)
      end

      # alias from File.expand_path
      # @param [String,Pa] path
      # @return [String]
      def expand2(path) 
        File.expand_path get(path) 
      end

      # shorten2 a path,
      # convert /home/user/file to ~/file
      #
      # @param [String,Pa] path
      # @return [String]
      def shorten2(path)
        get(path).sub /^#{Regexp.escape(ENV["HOME"])}/, "~"
      end

      alias shorten shorten2

      # real path
      def real2(path) 
        File.realpath get(path)
      end

      # get parent path
      # 
      # @param [String,Pa] path
      # @param [Fixnum] n up level
      # @return [String]
      def parent2(path, n=1)
        path = get(path)
        n.times do
          path = File.dirname(path)
        end
        path
      end

      DELEGATE_METHODS.each { |mth|
        mth2 = "#{mth}2"

        class_eval <<-EOF
          def #{mth}(*args, &blk)
            Pa(Pa.#{mth2}(*args, &blk))
          end
        EOF
      }
    end
  end
end

