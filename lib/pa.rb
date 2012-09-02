require "tmpdir"
require "pd"

=begin rdoc
Pa(Path) is similary to Pathname, but more powerful.
it combines fileutils, tmpdir, find, tempfile, File, Dir, Pathname

all class methods support Pa as parameter.

support "~/foo" path. Pa("~/foo") is "/home/x/foo"

Filename parts:
---------

	/home/guten.ogg

	  dir:    /home
	  base:   guten.ogg
    name:   guten
	  ext:    .ogg
    fext:   ogg

Examples:
---------

	pa = Pa('/home/a.vim')
	pa.dir2  	-> '/home'
	pa.base2 	-> 'a.vim'
  pa.name2   -> 'a'
	pa.ext2  	-> '.vim'

	pa.dir    -> Pa('/home')  # similar, but return <#Pa>

Additional method list
---------------------
* Pa.absolute _alias from `File.absolute_path`_
* Pa.expand _aliss from `File.expand_path`_

=== create, modify path

Example1:

	pa = Pa('/home/foo')
	pa.join2('a.txt')       -> '/home/foo/a.txt'
	pa.join('a.txt')        -> Pa('/home/foo/a.txt')

Example2:

	pa1 = Pa('/home/foo/a.txt')
	pa2 = Pa('/home/bar/b.txt')
	pa1+'~' #=> new Pa('/home/foo/a.txt~')
	Pa.join(pa1.dir, pa2.base) #=> '/home/foo/b.txt'

Example3:

	pa1 = Pa('/home/foo/a.txt')
	pa2 = Pa('/home/bar')
	pa2.join2(pa1.base)    -> '/home/bar/a.txt'
		
**Attributes**

  name     abbr    description

  path      p      
  absolute  a      absolute path
  dir       d      dirname of a path
  base      b      basename of a path
  ext       e      extname of a path
	name      n     filename without ext
  fext      fe     extname without "."

== used with rspec

	File.exists?(path).should be_true
	Pa(path).should be_exists

=end
class Pa 
  autoload :Util,    "pa/util"
  autoload :VERSION, "pa/version" 

	Error = Class.new Exception
	EUnkonwType = Class.new Error

  DELEGATE_CLASS_METHODS = [:absolute, :dir, :dir_stict, :name, :ext, :fext] 

  class << self
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
      if String === obj
        obj
      elsif obj.respond_to?(:path)
        obj.path
      elsif obj.nil?
        nil
      else
        raise ArgumentError, "Pa.get() not support type -- #{obj.inspect}(#{obj.class})"
      end
    end

    def absolute2(name, dir=".")
      File.absolute_path(get(name), dir)
    end

    # => ".", "..", "/", "c:"
    #
    # "foo" => "."
    # "./foo" => "."
    # "../../foo" => "../.."
    #
    def dir2(path) 
      File.dirname(get(path))
    end

    # Pa("foo") => ""
    # Pa("./foo") => "."
    def dir_strict2(path)
      dir = File.dirname(get(path))

      if %w[.].include?(dir) && path !~ %r~^\./~
        ""
      else
        dir
      end
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
      ret = base2(*args, &blk)

      if Array === ret
        [ Pa(ret[0]), ret[1] ]
      else
        Pa(ret)
      end
    end

    def name2(path)
      File.basename(get(path)).match(/^(.+?)(?:\.([^.]+))?$/)[1]
    end

      # -> ".ogg", ""  
    def ext2(path)
      File.extname(get(path))
    end

      # => "ogg", ""
    def fext2(path)
      File.extname(get(path)).gsub(/^\./, "") 
    end

    # split path
    #
    # @example
    #
    # 	path="/home/a/file"
    # 	split2(path)                -> ["/home/a", "file"]
    # 	split2(path, :all => true)  -> ["/", "home", "a", "file"]
    #
    # @param [String,Pa] path
    # @param [Hash] o option
    # @option o [Boolean] :all split all parts
    # @return [Array<String>] 
    def split2(path, o={})
      dir, base = File.split(get(path))
      ret = Util.wrap_array(File.basename(base))

      if o[:all]
        loop do
          dir1, base = File.split(dir)
          break if dir1 == dir
          ret.unshift base
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
    # @example
    #
    #  Pa.join2("", "foo", nil, "bar")  -> "foo/bar"
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

    DELEGATE_CLASS_METHODS.each {|meth|
      eval <<-EOF
        def #{meth}(*args, &blk)
          Pa(#{meth}2(*args, &blk))
        end
      EOF
    }

  private

    # wrap result to Pa
    def _wrap(obj)
      case obj
      when Array
        obj.map{|v| Pa(v)}
      when String
        Pa(obj)
      end
    end
  end

  DELEGATE_ATTR_METHODS2 = [ :dir2, :dir_strict2, :base2, :name2, :ext2, :fext2]
  DELEGATE_ATTR_METHODS = [ :absolute, :dir, :dir_strict, :rel, :rea ]
  DELEGATE_METHODS2 = [ :join2 ]
  DELEGATE_METHODS = [ :change, :join]
  DELEGATE_TO_PATH2 = [ :sub2, :gsub2 ]
  DELEGATE_TO_PATH = [:match, :start_with?, :end_with?]

	attr_reader :path2
  attr_reader :absolute2, :dir2, :dir_strict2, :base2, :name2, :short2, :ext2, :fext2, :rel2, :rea2
  attr_reader :options

  # @param [Hash] o option
  # @option o [String] rel relative path
  # @option o [String] base_dir
	# @param [String, #path] path
	def initialize(path, o={})
		@path2 = Pa.get(path)
    # convert ~ to ENV["HOME"]
    @path2.sub!(/^~/, ENV["HOME"].to_s) if @path2 # nil
    @options = o

    @base_dir = o[:base_dir] || "."

		initialize_variables
  end

	chainable = Module.new do
		def initialize_variables; end
	end
	include chainable

  DELEGATE_ATTR_METHODS2.each {|meth2|
    class_eval <<-EOF
      def #{meth2}(*args, &blk)
        @#{meth2} ||= Pa.#{meth2}(path, *args, &blk)
      end
    EOF
  }

  DELEGATE_ATTR_METHODS.each {|meth|
    class_eval <<-EOF
      def #{meth}(*args, &blk)
        @#{meth} ||= Pa(#{meth}2(*args, &blk))
      end
    EOF
  }

  DELEGATE_METHODS2.each { |meth2|
    class_eval <<-EOF
      def #{meth2}(*args, &blk)
        Pa.#{meth2}(path, *args, &blk)
      end
    EOF
  }

  DELEGATE_METHODS.each {|meth|
    class_eval <<-EOF
      def #{meth}(*args, &blk)
        Pa(#{meth}2(*args, &blk))
      end
    EOF
  }

  DELEGATE_TO_PATH2.each {|meth2|
    class_eval <<-EOF
      def #{meth2}(*args, &blk)
        path.#{meth2[0...-1]}(*args, &blk)
      end
    EOF
  }

  DELEGATE_TO_PATH.each {|meth|
    class_eval <<-EOF
      def #{meth}(*args, &blk)
        path.#{meth}(*args, &blk)
      end
    EOF
  }

  def base_dir
    @base_dir ||= (options[:base_dir] || ".")
  end

  def rel2
    @rel2 ||= (options[:rel] || "" )
  end

  def rea2
    @rea2 ||= options[:base_dir] ? File.join(base_dir, path) : path
  end

  def absolute2
    @absolute2 ||= Pa.absolute2(rea2)
  end

  # both x, x2 return String
	alias path path2
  alias base base2
  alias name name2
  alias ext ext2
  alias fext fext2

  # abbreviate
  alias p2 path2 
  alias p2 path
  alias a2 absolute2
  alias d2 dir2
  alias d_s2 dir_strict2
  alias	b2 base2
  alias n2 name2
  alias e2 ext2
  alias fe2 fext2
  alias p path
  alias b base
  alias n name
  alias e ext
  alias fe fext

  alias a absolute
  alias d dir
  alias d_s dir_strict

	# return '#<Pa @path="foo", @absolute="/home/foo">'
	#
	# @return [String]
	def inspect
		ret="#<" + self.class.to_s + " "
		ret += "@path=\"#{path}\", @absolute2=\"#{absolute2}\""
		ret += " >"
		ret
	end

	# return '/home/foo'
	#
	# @return [String] path
	def to_s
		path
	end

	# @param [String,#path]
	# @return [Pa] the same Pa object
	def replace(path)
		@path2 = Pa.get(path)

		initialize_variables
	end

  def ==(other)
    case other
    when Pa
      self.path == other.path
    else
      false
    end
  end

	def <=>(other)
    path <=> Pa.get(other)
	end

  def =~(regexp)
    path =~ regexp 
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

  def short2
    @short2 ||= Pa.shorten2(@path) 
  end

  def short
    @short ||= Pa(short2)
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
    replace path.sub(*args,&blk)
  end

  # @return [Pa]
  def gsub!(*args,&blk)
    replace path.gsub(*args,&blk)
  end

  # Change some parts of the path.
  #
  # path
  # dir base 
  # dir name ext
  # ...  
  #
  # @return [String] path
  def change2(data={}, &blk)
    return Pa.new(blk.call(self)) if blk

    if data[:path]
      return data[:path]
    elsif data[:base]
      return File.join(data[:dir] || dir2, data[:base])
    else
      dir, name, ext = data[:dir] || dir2, data[:name] || name2, data[:ext] || ext2

      File.join(dir, name)+ext
    end
  end
end

require "pa/path"
require "pa/cmd"
require "pa/directory"
require "pa/state"
class Pa
  include Path
  include Directory
  include State
  include Cmd
end

module Kernel
private
	# a very convient function.
	# 
	# @example
  #
	#   Pa('/home').exists? 
	def Pa(path, o={})
		return path if Pa===path
		Pa.new path, o
	end
end
