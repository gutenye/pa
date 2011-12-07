=begin
== ls family
	* Dir[*path] _support globbing_
	* Pa.glob(*path,o),(){} _support globbing with option and block_
	* each(path),(){} each_r(),(){} _support Enumerator. not support globbing_
	* ls(path) ls_r(path) _sample ls. not support globbing._

=== Example	
	tmp/
		filea
		dira/fileb

	ls2("tmp") => ["filea", "dira"]
	ls2_r("tmp") => ["filea", "dira", "dira/fileb"]
	ls2_r("tmp"){|path, rel| rel.count('/')==1} => ["dira/fileb"]

	each("tmp") => Enumerate<Pa>
	each("tmp") {|pa| Pa.rm pa if pa.file?}
	each("tmp").with_object([]){|pa,m| m<<pa.dir} #=> ["tmp", "tmp/dira"]

=end
class Pa
  module Directory
    extend Util::Concern

    module ClassMethods
      # path globbing, exclude '.' '..' for :dotmatch
      # @note glob is * ** ? [set] {a,b}
      #
      # @overload glob2(*paths, o={})
      # 	@param [String] path
      # 	@param [Hash] o option
      # 	@option o [Boolean] :dotmatch glob not match dot file by default.
      # 	@option o [Boolean] :pathname wildcard doesn't match /
      # 	@option o [Boolean] :noescape makes '\\' ordinary
      # 	@return [Array<String>] 
      # @overload glob2(*paths, o={})
      #   @yieldparam [String] path
      #   @return [nil]
      def glob2(*args, &blk)
        paths, o = Util.extract_options(args)
        paths.map!{|v|get(v)}
        blk ||= proc { |path| path }

        flag = 0
        o.each do |option, value|
          flag |= File.const_get("FNM_#{option.upcase}") if value
        end

        files = Dir.glob(paths, flag)

        # delete . .. for '.*'
        %w(. ..).each {|v| files.delete(v)}

        ret = []
        files.each { |path|
          ret << blk.call(path)
        }

        ret
      end

      def glob(*args, &blk)
        args, o = Util.extract_options(args)
        ret = []
        blk ||= proc { |path| path }

        glob2 *args, o do |path|
          ret << blk.call(Pa(path))
        end

        ret
      end

      # is directory empty?
      #
      # @param [String] path
      # @return [Boolean]
      def empty?(path)
        Dir.entries(get(path)).empty? 
      end

      # traverse directory 
      # @note raise Errno::ENOTDIR, Errno::ENOENT  
      #
      # @example
      #   each '.' do |pa|
      #     p pa.path #=> "foo" not "./foo"
      #   end
      #   # => '/home' ..
      #
      #  each('.', error: true).with_object([]) do |(pa,err),m|
      #    ...
      #  end
      #
      # @overload each(path=".", o={})
      #   @param [String,Pa] path
      #   @prarm [Hash] o
      #   @option o [Boolean] :nodot (false) include dot file
      #   @option o [Boolean] :nobackup (false) include backup file
      #   @option o [Boolean] :error (false) yield(pa, err) instead of raise Errno::EPERM when Dir.open(dir)
      #   @return [Enumerator<String>]
      # @overload each(path=".", o={})
      #   @yieldparam [String] path
      #   @return [nil]
      def each2(*args, &blk) 
        return Pa.to_enum(:each2, *args) unless blk

        (path,), o = Util.extract_options(args)
        path = path ? get(path) : "."
        raise Errno::ENOENT, "`#{path}' doesn't exists."  unless File.exists?(path)
        raise Errno::ENOTDIR, "`#{path}' not a directoy."  unless File.directory?(path)

        begin
          dir = Dir.open(path)
        rescue Errno::EPERM => err
        end
        raise err if err and !o[:error]

        while (entry=dir.read)
          next if %w(. ..).include? entry
          next if o[:nodot] and entry=~/^\./
          next if o[:nobackup] and entry=~/~$/

          # => "foo" not "./foo"
          pa = path=="." ? entry : File.join(path, entry)
          blk.call pa, err  
          end
        end

      def each(*args, &blk)
        args, o = Util.extract_options(args)
        each2 *args, o do |path, err|
          blk.call Pa(path), err
        end
      end

      # each with recursive
      # @see each2
      #
      # * each2_r() skip Exception
      # * each2_r(){path, relative, err}
      #
      # @overload each2_r(path=".", o={})
      #   @return [Enumerator<String>]
      # @overload each2_r(path=".", o={})
      #   @yieldparam [String] path
      #   @yieldparam [String] relative relative path
      #   @yieldparam [Errno::ENOENT,Errno::EPERM] err 
      #   @return [nil]
      def each2_r(*args, &blk)
        return Pa.to_enum(:each2_r, *args) if not blk

        (path,), o = Util.extract_options(args)
        path ||= "."

        _each2_r(path, "", o, &blk)
      end

      def each_r(*args, &blk)
        args, o = Util.extract_options(args)
        each2_r *args, o do |path, err|
          blk.call path, err
        end
      end

      # list directory contents
      # @see each2
      #
      # block form is a filter.
      #
      # @Example
      #   Pa.ls2(".") {|path, fname| Pa.directory?(path)} # list only directories
      #
      # @overload ls2(path=".", o={})
      # 	@return [Array<String>]
      # @overload ls2(path=".", o={})
      #   @yieldparam [String] path
      #   @yieldparam [String] fname
      #   @return [Array<String>]
      def ls2(*args, &blk)
        blk ||= proc { true }
        each2(*args).with_object([]) { |(path),m| 
          base = File.basename(path)
          ret = blk.call(path, base)
          m << base if ret
        }
      end

      def ls(*args, &blk)
        args, o = Util.extract_options(args)
        blk ||= proc { true }

        ls2 *args do |path, fname|
          ret = blk.call(Pa(path), fname)
          m << fname if ret 
        end
      end

      # ls2 with recursive
      # @see ls2
      #
      # @overload ls2_r(path=".", o={})
      # 	@return [Array<String>]
      # @overload ls2_r(path=".", o={})
      #   @yieldparam [Pa] pa
      #   @yieldparam [String] rel
      #   @return [Array<String>]
      def ls2_r(*args, &blk)
        blk ||= proc {true}
        each2_r(*args).with_object([]) { |(path,rel),m| 
          m<<rel if blk.call(path, rel)
        }
      end

      def ls_r(*args, &blk)
        args, o = Util.extract_options(args)
        ls2_r(*args, o, &blk)
      end

    private
      # @param [String] path
      def _each2_r(path, relative, o, &blk)
        o.merge!(error: true)

        Pa.each2(path, o) do |path2, err|
          # fix for File.join with empty string
          joins=[ relative=="" ? nil : relative, File.basename(path2)].compact
          relative2 = File.join(*joins)

          blk.call path2, relative2, err

          if File.directory?(path2)
            _each2_r(path2, relative2, o, &blk)
          end
        end
      end
    end
  end
end
