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

      def tmpdir2
        Dir.tmpdir
      end

      def tmpdir
        Pa(Dir.tmpdir)
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
      #   @option o [Boolean] :dot (true) include dot file
      #   @option o [Boolean] :backup (true) include backup file
      #   @option o [Boolean] :absolute (false) return absolute path
      #   @option o [Boolean] :error (false) yield(pa, err) instead of raise Errno::EPERM when Dir.open(dir)
      #   @option o [Boolean] :file (false) return path and not raise Errno:ENOTDIR if path is a file.
      #   @return [Enumerator<String>]
      # @overload each(path=".", o={})
      #   @yieldparam [String] path
      #   @return [nil]
      def each2(*args, &blk) 
        return Pa.to_enum(:each2, *args) unless blk

        (path,), o = Util.extract_options(args)
        o = {dot: true, backup: true}.merge(o)

        path = path ? get(path) : "."
        raise Errno::ENOENT, "`#{path}' doesn't exists."  unless File.exists?(path)

        if not File.directory?(path) 
          if o[:file]
            blk.call(path)
            return
          else
            raise Errno::ENOTDIR, "`#{path}' is not a directoy."
          end
        end

        begin
          dir = Dir.open(path)
        rescue Errno::EPERM => err
        end
        raise err if err and !o[:error]

        while (entry=dir.read)
          next if %w(. ..).include? entry
          next if not o[:dot] and entry=~/^\./
          next if not o[:backup] and entry=~/~$/

          p = if o[:absolute]
            File.absolute_path(File.join(path, entry))
          else
            # => "foo" not "./foo"
             path=="." ? entry : File.join(path, entry)
          end

          blk.call p, err  
          end
        end

      def each(*args, &blk)
        return Pa.to_enum(:each, *args) unless blk

        args, o = Util.extract_options(args)
        each2(*args, o) { |path, err|
          blk.call Pa(path), err
        }
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
        return Pa.to_enum(:each_r, *args) if not blk

        args, o = Util.extract_options(args)
        each2_r *args, o do |path, err|
          blk.call Pa(path), err
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
        paths, o = Util.extract_options(args)
        paths << "." if paths.empty?
        blk ||= proc { true }

        paths.each.with_object([]) { |path, m|
          each2(path, o) { |path2|
            base = File.basename(path2)
            file = o[:absolute] ? path2 : base

            m << file if blk.call(path2, base)
          }
        }
      end

      # @overload ls(*paths, o={})
      #   @params [Array] paths (["."])
      # 	@return [Array<Pa>]
      # @overload ls(*paths, o={}){|path, fname|}
      #   @yieldparam [Pa] path
      #   @yieldparam [String] fname
      #   @return [Array<String>]
      def ls(*args, &blk)
        paths, o = Util.extract_options(args)
        blk ||= proc { true }
        ret = []

        ls2(*paths, o) { |path, fname|
          file = o[:absolute] ? path : fname

          ret << Pa(file) if blk.call(Pa(path), fname)
        }

        ret
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
          m << rel if blk.call(path, rel)
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

    module InstanceMethods
      DELEGATE_METHODS = [:each2, :each, :each2_r, :each_r, :ls2, :ls]

      DELEGATE_METHODS.each { |mth|
        class_eval <<-EOF
          def #{mth}(*args, &blk)
            Pa.#{mth}(path, *args, &blk)
          end
        EOF
      }
    end
  end
end
