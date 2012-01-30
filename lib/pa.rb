require "tmpdir"

=begin rdoc
Pa(Path) is similary to Pathname, but more powerful.
it combines fileutils, tmpdir, find, tempfile, File, Dir, Pathname

all class methods support Pa as parameter.

Examples:
---------
	pa = Pa('/home/a.vim')
	pa.dir  	#=> '/home'
	pa.base 	#=> 'a.vim'
	pa.name 	#=> 'a'
	pa.ext  	#=> 'vim'
	pa.fext		#=> '.vim'

	pa.dir_pa #=> Pa('/home')  # similar, but return <#Pa>

Filename parts:
---------
	/home/guten.ogg
	  base: guten.ogg
	  dir: /home
	  ext: ogg
	  name: guten

Additional method list
---------------------
* Pa.absolute _alias from `File.absolute_path`_
* Pa.expand _aliss from `File.expand_path`_

=== create, modify path
Example1:
	pa = Pa('/home/foo')
	pa.join('a.txt') #=> new Pa('/home/foo/a.txt')

Example2:
	pa1 = Pa('/home/foo/a.txt')
	pa2 = Pa('/home/bar/b.txt')
	pa1+'~' #=> new Pa('/home/foo/a.txt~')
	Pa.join(pa1.dir, pa2.base) #=> '/home/foo/b.txt'

Example3:
	pa1 = Pa('/home/foo/a.txt')
	pa2 = Pa('/home/bar')
	pa2.join(pa1.base)  #=> new Pa('/home/bar/a.txt')
		
**Attributes**

  name     abbr    description

  path      p      
  absolute  a      absolute path
  dir       d      dirname of a path
  base      b      basename of a path
	fname     fn     alias of base
  name      n      filename of a path
  ext       e      extname of a path,  return "" or "ogg"  
  fext      fe     return "" or ".ogg"

== used with rspec

	File.exists?(path).should be_true
	Pa(path).should be_exists

=end
class Pa 
  autoload :Util,    "pa/util"
  autoload :VERSION, "pa/version" 

	Error = Class.new Exception
	EUnkonwType = Class.new Error

  class << self
    DELEGATE_METHODS = [:join, :build]

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

    # build a path
    # options :path, :dir, :fname, :base, :name, :fext, :ext
    # use Pa.join2
    # @example
    # 
    #  Pa.build2(dir: "/home", name: "guten", ext: "avi") => "/home/guten.avi
    #  Pa.build2("/home/guten.avi") { |pa| "#{pa.dir}/foo.#{pa.ext}" } => "/home/foo.avi
    #
    # @overload build2(path){|pa|=>String}
    # @overload build2(data={})
    # @overload build2(data={}){}
    def build2(*args, &blk)
      data = Hash===args.last ? args.pop : {}
      path = args[0] || build_path2(data)
      blk ||= proc {|pa| pa.p }

      blk.call(Pa(path))
    end

    DELEGATE_METHODS.each { |mth| 
      class_eval <<-EOF
        def #{mth}(*args, &blk)
          Pa(Pa.#{mth}2(*args, &blk))
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

    def build_path2(data={})
      if data[:path]
        path = data[:path]
      elsif data[:fname] || data[:base]
        path = join2(data[:dir], data[:fname] || data[:base])
      else
        path = join2(data[:dir], data[:name])
        if data[:fext]
          path << data[:fext]
        elsif data[:ext]
          path << ".#{data[:ext]}"
        end
      end

      path
    end
  end

  DELEGATE_METHODS2 = [ :join2 ]
  DELEGATE_METHODS = [ :dir, :build, :join ]

	attr_reader :path2
  attr_reader :absolute2, :dir2, :dir_strict2, :base2, :fname2, :name2, :short2, :ext2, :fext2

	# @param [String, #path] path
	def initialize(path)
		@path2 = Pa.get(path)

		initialize_variables
  end

	chainable = Module.new do
		def initialize_variables; end
	end
	include chainable

  def absolute2
    @absolute2 ||= File.absolute_path(path)
  end

  # => ".", "..", "/", "c:"
  def dir2
    @dir2 ||= File.dirname(path)
  end

  # Pa("foo") => ""
  # Pa("./foo") => "."
  def dir_strict2
    return @dir_strict2 if @dir_strict2

    dir = File.dirname(path)

    @dir_strict2 = if %w[. ..].include?(dir) && path !~ %r!^\.\.?/!
      ""
    else
      dir
    end
  end

  def base2
    @base2 ||= File.basename(path)
  end

  def name2
    @name2 ||= File.basename(path).match(/^(.+?)(?:\.([^.]+))?$/)[1]
  end

  # => "ogg", ""  
  def ext2
    @ext2 ||= File.basename(path).match(/^(.+?)(?:\.([^.]+))?$/)[2] || ""
  end

  # => ".ogg", ""
  def fext2
    @fext2 ||= ext2.empty? ? "" : ".#{ext2}"
  end

  alias fname2 base2

  # both x, x2 return String
	alias path path2
  alias base base2
  alias fname fname2
  alias name name2
  alias ext ext2
  alias fext fext2

  # abbretive
  alias p2 path2 
  alias p2 path
  alias a2 absolute2
  alias d2 dir2
  alias d_s2 dir_strict2
  alias	b2 base2
  alias n2 name2
  alias fn2 fname2
  alias e2 ext2
  alias fe2 fext2
  alias p path
  alias b base
  alias fn fname
  alias n name
  alias e ext
  alias fe fext

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

  # @return [String]
  def build2(data={}, &blk)
    return Pa.new(blk.call(self)) if blk

    d = if data[:path]
      {path: data[:path]}
    elsif data[:fname] || data[:base]
      {dir: dir_strict2, fname: data[:fname], base: data[:base]}
    else
      {dir: dir_strict2, name: name2, ext: ext2}.merge(data)
    end

    Pa.build2(d)
  end

  DELEGATE_METHODS2.each { |mth2|
    class_eval <<-EOF
      def #{mth2}(*args, &blk)
        Pa.#{mth2}(path, *args, &blk)
      end
    EOF
  }

  DELEGATE_METHODS.each {|mth|
    class_eval <<-EOF
      def #{mth}(*args, &blk)
        Pa(#{mth}2(*args, &blk))
      end
    EOF
  }
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
	#   Pa('/home').exists? 
	def Pa(path)
		return path if Pa===path
		Pa.new path
	end
end
