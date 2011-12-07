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
	NAME_EXT_PAT = /^(.+?)(?:\.([^.]+))?$/
  module Path
    extend Util::Concern

    module ClassMethods
      # get path of an object. 
      #
      # return obj#path if object has a 'path' instance method
      #
      # nil -> nil
      #
      #
      # @param [String,#path] obj
      # @return [String,nil] path
      def get(obj)
        if obj.respond_to?(:path)
          obj.path
        elsif String === obj 
          obj
        elsif obj.nil?
          nil
        else
          raise ArgumentError, "Pa.get() not support type -- #{obj.inspect}(#{obj.class})"
        end
      end

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
          name, ext = name.match(NAME_EXT_PAT).captures
          [ name, (ext || "")]
        else
          name
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
       
      # split path
      #
      # @example
      # 	path="/home/a/file"
      # 	split2(path)  #=> "/home/a", "file"
      # 	split2(path, :all => true)  #=> "/", "home", "a", "file"
      #
      # @param [String,Pa] name
      # @param [Hash] o option
      # @option o [Boolean] :all split all parts
      # @return [Array<String>] 
      def split2(name, o={})
        dir, fname = File.split(get(name))
        ret = Util.wrap_array(File.basename(fname))

        if o[:all]
          loop do
            dir1, fname = File.split(dir)
            break if dir1 == dir
            ret.unshift fname
            dir = dir1
          end
        end
        ret.unshift dir
        ret
      end

      # special case
      def split(*args)
        dir, *names = split2(*args)
        [ Pa(dir), *names]
      end

      # join paths, skip nil and empty string.
      #
      # @param [*Array<String>] *paths
      # @return [String]
      def join2(*paths)
        paths.map!{|v|get(v)}

        # skip nil
        paths.compact!

        # skip empty string
        paths.delete("")

        File.join(*paths)
      end
    end

    module InstanceMethods
      # @return [String] 
      attr_reader :absolute2, :dir2, :base2, :name2, :short2

      # @return [String] ext "", "ogg"
      attr_reader :ext2

      # @return [String] ext "", ".ogg"
      attr_reader :fext2

      def initialize_variables
        super
        @absolute2 = File.absolute_path(@path) 
        @dir2 = File.dirname(@path)
        @base2 = File.basename(@path) 
        @name2, @ext2 = @base2.match(NAME_EXT_PAT).captures
        @ext2 ||= ""
        @fext2 = @ext2.empty? ? "" : "."+@ext2
      end

      alias a2 absolute2
      alias d2 dir2
      alias	b2 base2
      alias n2 name2
      alias fname2 base2
      alias fn2 fname2
      alias e2 ext2
      alias fe2 fext2

      # fix name,2 => String
      alias base base2
      alias fname fname2
      alias name name2
      alias ext ext2
      alias fext fext2

      alias b base
      alias fn fname
      alias n name
      alias e ext
      alias fe fext

      def short2
        @short2 ||= Pa.shorten2(@path) 
      end

      # add string to path
      # 
      # @example 
      #  pa = Pa('/home/foo/a.txt')
      #  pa+'~' #=> new Pa('/home/foo/a.txt~')
      #
      # @param [String] str
      # @return [Pa]
      def +(str)
        Pa(path+str)
      end

      # @return [String]
      def sub2(*args, &blk)
        path.sub(*args, &blk)
      end

      # @return [String]
      def gsub2(*args, &blk)
        path.gsub(*args, &blk)
      end

      # @return [Pa]
      def sub(*args, &blk)
        Pa(sub2(*args, &blk))
      end

      # @return [Pa]
      def gsub(*args, &blk)
        Pa(gsub2(*args, &blk))
      end

      # @return [Pa]
      def sub!(*args,&blk)
        self.replace path.sub(*args,&blk)
      end

      # @return [Pa]
      def gsub!(*args,&blk)
        self.replace path.gsub(*args,&blk)
      end

      # @return [MatchData]
      def match(*args,&blk)
        path.match(*args,&blk)
      end 

      # @return [Boolean]
      def start_with?(*args)
        path.start_with?(*args)
      end

      # @return [Boolean]
      def end_with?(*args)
        path.end_with?(*args)
      end

      def =~(regexp)
        path =~ regexp 
      end

      def ==(other)
        case other
        when Pa
          self.path == other.path
        else
          false
        end
      end
    end
  end
end

