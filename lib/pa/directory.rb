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
      #   @option o [Boolean] :error (false) yield(pa, err) instead of raise Errno::EPERM when Dir.open(dir)
      #   @option o [Boolean] :file (false) return path and not raise Errno:ENOTDIR if path is a file.
      #   @option o [String] :base_dir (nil) base directory.
      #   @return [Enumerator<String>]
      # @overload each(path=".", o={}){|path, abs, fname, err, [rea]|}
      #   @yieldparam [String] path
      #   @yieldparam [String] abs absolute path
      #   @yieldparam [String] fname a basename
      #   @yieldparam [String] err error
      #   @yieldparam [String] rea real relative path with o[:base_dir]
      #   @return [nil]
      def each2(*args, &blk) 
        return Pa.to_enum(:each2, *args) unless blk

        (dir,), o = Util.extract_options(args)
        dir = dir ? get(dir) : "."
        o = {dot: true, backup: true}.merge(o)

        rea_dir = o[:base_dir] ? File.join(o[:base_dir], dir) : dir
        raise Errno::ENOENT, "`#{rea_dir}' doesn't exists."  unless File.exists?(rea_dir)

        if not File.directory?(rea_dir) 
          if o[:file]
            rea_path = rea_dir
            blk.call dir, File.absolute_path(rea_path), File.basename(rea_path), nil, rea_path
            return
          else
            raise Errno::ENOTDIR, "`#{rea_dir}' is not a directoy."
          end
        end

        begin
          d = Dir.open(rea_dir)
        rescue Errno::EPERM => err
        end
        raise err if err and !o[:error]

        while (entry=d.read)
          next if %w(. ..).include? entry
          next if not o[:dot] and entry=~/^\./
          next if not o[:backup] and entry=~/~$/

          path = Util.join(dir, entry)
          rea_path = Util.join(rea_dir, entry)
          blk.call path, File.absolute_path(rea_path), File.basename(rea_path), err, rea_path
        end
      end

      def each(*args, &blk)
        return Pa.to_enum(:each, *args) unless blk

        args, o = Util.extract_options(args)
        each2(*args, o) { |path, abs, fname, err, rea|
          blk.call Pa(path), abs, fname, err, rea
        }
      end

      # each with recursive
      # @see each2
      #
      # * each2_r() skip Exception
      # * each2_r(){path, relative, err}
      #
      # @overload each2_r(path=".", o={})
      #   @option o [String] :base_dir (nil) base directory.
      #   @return [Enumerator<String>]
      # @overload each2_r(path=".", o={})
      #   @yieldparam [String] path
      #   @yieldparam [String] abs
      #   @yieldparam [String] rel/rea relative path
      #   @yieldparam [Errno::ENOENT,Errno::EPERM] err 
      #   @return [nil]
      def each2_r(*args, &blk)
        return Pa.to_enum(:each2_r, *args) if not blk

        (dir,), o = Util.extract_options(args)
        dir ||= "."

        _each2_r(dir, "", o, &blk)
      end

      def each_r(*args, &blk)
        return Pa.to_enum(:each_r, *args) if not blk

        args, o = Util.extract_options(args)
        each2_r *args, o do |path, abs, rel, err, rea|
          blk.call Pa(path), abs, rel, err, rea
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
      # @overload ls2(*dirs, o={})
      #   @option o [Boolean] :absolute (false) return absolute path instead.
      #   @option o [Boolean] :include (false) return "<path>/foo"
      # 	@return [Array<String>]
      # @overload ls2(*dirs, o={}){|path, abs, fname|}
      #   @yieldparam [String] path
      #   @yieldparam [String] abs
      #   @yieldparam [String] fname
      #   @return [Array<String>]
      def ls2(*args, &blk)
        dirs, o = Util.extract_options(args)
        dirs << "." if dirs.empty?
        blk ||= proc { true }

        dirs.each.with_object([]) { |dir, m|
          each2(dir, o) { |path, abs, fname, err, rea|

            view_path = if o[:absolute]
                     abs
                   elsif o[:include]
                     path
                   else
                     fname
                   end

            m << view_path if blk.call(path, abs, fname, err, rea)
          }
        }
      end

      # ls2 with recursive
      # @see ls2
      #
      # @overload ls2_r(*dirs, o={})
      # 	@return [Array<String>]
      # @overload ls2_r(*dirs, o={}){|pa, abs, rel, err, [rea]|
      #   @yieldparam [String] path
      #   @yieldparam [String] abs
      #   @yieldparam [String] rel
      #   @yieldparam [Exception] err
      #   @yieldparam [String] rea
      #   @return [Array<String>]
      def ls2_r(*args, &blk)
        dirs, o = Util.extract_options(args)
        dirs << "." if dirs.empty?
        blk ||= proc { true }

        dirs.each.with_object([]) { |dir, m|
          each2_r(dir, o) { |path, abs, rel, err, rea|
            view_path = if o[:absolute]
                     abs
                   elsif o[:include]
                     path
                   else
                     rel
                   end

            m << view_path if blk.call(path, abs, rel, err, rea)
          }
        }
      end

      # @overload ls(*paths, o={})
      #   @params [Array] paths (["."])
      # 	@return [Array<Pa>]
      # @overload ls(*paths, o={}){|pa, abs, fname, err, [rea]|}
      #   @yieldparam [Pa] pa
      #   @yieldparam [String] abs
      #   @yieldparam [String] fname
      #   @yieldparam [Exception] err
      #   @yieldparam [String] rea
      #   @return [Array<String>]
      def ls(*args, &blk)
        dirs, o = Util.extract_options(args)
        blk ||= proc { true }
        ret = []

        ls2(*dirs, o) { |path, abs, fname, err, rea|
          view_path = if o[:absolute]
                   abs
                 elsif o[:include]
                   path
                 else
                   fname
                 end

          ret << Pa(view_path) if blk.call(Pa(path), abs, fname, err, rea)
        }

        ret
      end

      def ls_r(*args, &blk)
        args, o = Util.extract_options(args)
        ls2_r(*args, o, &blk)
      end

    private

      # I'm rescurive.
      # @param [String] path
      def _each2_r(path, relative, o, &blk)
        relative = relative == "" ? nil : relative
        o.merge!(error: true)

        Pa.each2(path, o) do |path2, abs, fname, err, rea|
          # fix for File.join with empty string
          rel = File.join(*[relative, File.basename(path2)].compact)
          rea = o[:base_dir] ? File.join(o[:base_dir], rel) : rel

          blk.call path2, abs, rel, err, rea

          if File.directory?(abs)
            _each2_r(path2, rel, o, &blk)
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
