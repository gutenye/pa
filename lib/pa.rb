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
    def method_missing(name, *args, &blk)
      # dir -> dir2
      name2 = "#{name}2".to_sym
      if public_methods.include?(name2)
        ret = __send__(name2, *args)
        return case ret
        when Array
          ret.map{|v| Pa(v)}
        when String
          Pa(ret)
        end
      end

      raise NoMethodError, "no method -- #{name}"
    end
  end

	attr_reader :path
	alias p path
  alias path2 path
  alias p2 path

	# @param [String,#path] path
	def initialize(path)
		@path = path.respond_to?(:path) ? path.path : path
		initialize_variables
	end

	chainable = Module.new do
		def initialize_variables; end
	end
	include chainable

	# @param [String,#path]
	# @return [Pa] the same Pa object
	def replace(path)
		@path = path.respond_to?(:path) ? path.path : path
		initialize_variables
	end

	# return '#<Pa @path="foo", @absolute="/home/foo">'
	#
	# @return [String]
	def inspect
		ret="#<" + self.class.to_s + " "
		ret += "@path=\"#{path}\", @absolute=\"#{absolute}\""
		ret += " >"
		ret
	end

	# return '/home/foo'
	#
	# @return [String] path
	def to_s
		@path
	end

	# missing method goes to Pa.class-method 
	def method_missing(name, *args, &blk)
		ret = self.class.__send__(name, path, *args, &blk)

		case ret	
		# e.g. readlink ..
		when String
			Pa(ret)
		# e.g. directory? 
		else
			ret
		end

	end

	def <=> other
		other_path = if other.respond_to?(:path) 
			 other.path
			elsif String === other
				other
			else
				raise Error, "not support type -- #{other.class}"
			end

		path <=> other_path 
	end
end

require "pa/path"
require "pa/cmd"
require "pa/dir"
require "pa/state"
class Pa
  include Path
  include Dir
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
