require "securerandom"

=begin
rm family
	* rm     _rm file only_
	* rmdir  _rm directory only_
	* rm_r   _rm recurive, both file and directory_
	* rm_if  _with condition, use rm_r_
=== Example 
  rm path # it's clear: remove a file
  rmdir path #  it's clear: remove a directory

:verbose and :show_cmd options, almost every cmd has these two options.

Pa.mv "dira", "dirb", :show_cmd => true
  > mv dira dirb

Pa.mv "dira", "dirb", :verbose => true
  > rename dira/filea dirb/filea
  > rename dira/fileb dirb/fileb

Pa.touch "a b c", :show_cmd => true
 > touch a b c

Pa.touch "a b c", :verbose => true
 > touch a
 > touch b
 > touch c
=end
class Pa
  module Cmd
    extend Util::Concern
    module ClassMethods
      DELEGATE_METHODS = [ :home ]

      def home2
        Dir.home 
      end

      # link
      #
      # @overload ln(src, dest)
      # @overload ln([src,..], directory)
      #
      # @param [Array<String>, String] src_s support globbing
      # @param [String,Pa] dest
      # @param [Hash] o
      # @option o [Boolean] :show_cmd puts cmd
      # @option o [Boolean] :verbose verbose mode
      # @return [nil]
      def ln(src_s, dest, o={})
        _ln(:link, src_s, dest, o) 
      end

      # ln force
      #
      # @see ln
      # @return [nil]
      def ln_f(src_s, dest, o={})
        o[:force] = true
        _ln(:link, src_s, dest, o) 
      end

      # symbol link
      #
      # @see ln
      # @return [nil]
      def symln(src_s, dest, o={})
        _ln(:symlink, src_s, dest, o) 
      end
      alias symlink ln

      # symln force
      #
      # @see ln
      # @return [nil]
      def symln_f(src_s, dest, o={})
        o[:force]=true
        _ln(:symlink, src_s, dest, o) 
      end

      # @see File.readlink
      def readlink(path)
        File.readlink(File.absolute_path(get(path), ".")) # jruby rbx
      end

      # change directory
      #
      # @param [String,Pa] path
      # @param [Hash] o
      # @option o [Boolean] :verbose verbose mode
      # @option o [Boolean] :show_cmd puts cmd
      def cd(path=ENV["HOME"], o={}, &blk)
        p = get(path)
        puts "cd #{p}" if (o[:verbose] or o[:show_cmd])
        Dir.chdir(p, &blk) 
      end

      # chroot
      # @see {Dir.chroot}
      #
      # @param [String] path
      # @param [Hash] o
      # @option o [Boolean] :verbose verbose mode
      # @option o [Boolean] :show_cmd puts cmd
      # @return [nil]
      def chroot(path, o={})
        p = get(path)
        puts "chdroot #{p}" if (o[:verbose] or o[:show_cmd])
        Dir.chroot(p)
      end

      # touch a blank file
      #
      # @overload touch(*paths, o={})
      #   @param [String] *paths
      #   @param [Hash] o option
      #   @option o [Fixnum,String] :mode (0664)
      #   @option o [Boolean] :mkdir auto mkdir if path contained directory not exists.
      #   @option o [Boolean] :force 
      #   @option o [Boolean] :verbose verbose mode
      #   @option o [Boolean] :show_cmd puts cmd
      #   @return [nil]
      def touch(*args)
        paths, o = Util.extract_options(args)
        _touch(paths, o) 
      end

      # touch force
      # @see touch
      #
      # @overload touch_f(*paths, o={})
      #   @return [nil]
      def touch_f(*args)
        paths, o = Util.extract_options(args)
        o[:force] = true
        _touch(paths, o) 
      end

      # make a directory
      #
      # @overload mkdir(*paths, o={})
      #   @param [String, Pa] *paths
      #   @param [Hash] o option
      #   @option o [Fixnum] :mode (0775)
      #   @option o [Boolean] :force
      #   @option o [Boolean] :verbose verbose mode
      #   @option o [Boolean] :show_cmd puts cmd
      #   @return [nil]
      def mkdir(*args)
        paths, o = Util.extract_options(args)
        _mkdir(paths, o) 
      end

      # mkdir force
      # @see mkdir
      #
      # @overload mkdir_f(*paths, o={})
      #   @return [nil]
      def mkdir_f(*args)
        paths, o = Util.extract_options(args)
        o[:force]=true
        _mkdir(paths, o)
      end

      # make temp directory
      #
      # @overload mktmpdir(name, o={}, &blk)
      #   @param [Hash] o options
      #   @option o [String] :tmpdir (ENV["TEMP"])
      #   @option o [Symbol] :verbose verbose mode
      #   @option o [Symbol] :show_cmd puts cmd
      #   @return [String] path
      # @overload mktmpdir(o={}, &blk) # name=$$
      def mktmpdir(*args, &blk)
        (name,), o = Util.extract_options(args)

        p = _mktmpname(name, o)
        puts "mktmpdir #{p}" if (o[:verbose] or o[:show_cmd])

        Dir.mkdir(p)

        begin 
          blk.call(p) 
        ensure 
          Dir.delete(p) 
        end if blk

        p
      end # def mktmpdir

      # make temp file
      # @see mktmpdir
      #
      # @overload mktmpfile2(name=$$, o={}, &blk)
      #   @param [Hash] o options
      #   @option o [Boolean] :verbose verbose mode
      #   @option o [Boolean] :show_cmd puts cmd
      #   @option o [String] :tmpdir
      #   @return [String] path
      def mktmpfile2(*args, &blk) 
        (name,), o = Util.extract_options(args)

        p = _mktmpname(name, o) 
        puts "mktmpfile #{p}" if (o[:verbose] or o[:show_cmd])

        begin 
          blk.call(p) 
        ensure
          File.delete(p)
        end if blk

        p
      end

      # @return [Pa] path
      def mktmpfile(*args, &blk)
        (name,), o = Util.extract_options(args)

        p = _mktmpname(name, o) 
        puts "mktmpfile #{p}" if (o[:verbose] or o[:show_cmd])

        begin 
          blk.call(Pa(p)) 
        ensure
          File.delete(p)
        end if blk

        Pa(p)
      end

      # rm file only
      #
      # @overload rm(*paths, o={})
      #   @param [String] *paths support globbing
      #   @param o [Boolean] :verbose verbose mode
      #   @param o [Boolean] :show_cmd puts cmd
      # @return [nil]
      def rm(*paths)
        paths, o = Util.extract_options(paths)
        extra_doc = o[:force] ? "-f " : nil
        puts "rm #{extra_doc}#{paths.join(" ")}" if o[:show_cmd]

        Pa.glob(*paths) { |pa|
          puts "rm #{extra_doc}#{pa.p}" if o[:verbose]

          if File.directory?(pa.p)
            if o[:force]
              next 
            else 
              raise Errno::EISDIR, "is a directory -- #{pa.p}" 
            end
          end
          next if pa.directory?
          File.delete(pa.p)
        }
      end

      def rm_f(*paths)
        paths, o = Util.extract_options(paths)
        o[:force] = true
        rm *paths, o
      end

      # rm directory only. still remove if directory is not empty.
      #
      # @param [String] *paths support globbing
      # @param [Hash] o options
      # @option o [Boolean] :verbose verbose mode
      # @option o [Boolean] :show_cmd puts cmd
      # @return [nil]
      def rmdir(*paths)
        paths, o = Util.extract_options(paths)
        extra_doc = o[:force] ? "-f " : nil
        puts "rmdir #{extra_doc}#{paths.join(" ")}" if o[:show_cmd]
        Pa.glob(*paths) { |pa|
          puts "  rmdir #{extra_doc}#{pa.p}" if o[:verbose]

          if not File.directory?(pa.p)
            if o[:force]
              next 
            else 
              raise Errno::ENOTDIR, "not a directory -- #{pa.p}" 
            end
          end
          _rmdir(pa)
        }
      end

      def rmdir_f(*paths)
        paths, o = Util.extract_options(paths)
        o[:force] = true
        rmdir *paths, o
      end
      
      # empty a directory.
      #
      # @example
      #
      #  empty_dir("foo")
      #
      # @param [String] *dirs
      # @param [Hash] o options
      # @option o [Boolean] :verbose verbose mode
      # @option o [Boolean] :show_cmd puts cmd
      # @return [nil]
      def empty_dir(*dirs)
        dirs, o = Util.extract_options(dirs)
        extra_doc = o[:force] ? "-f " : nil
        puts "empty_dir #{extra_doc}#{dirs.join(" ")}" if o[:show_cmd]

        dirs.each {|dir|
          dir = Pa(dir)
          if not File.exists?(dir.p)
            raise Errno::ENOENT, "not exists -- #{dir}" unless o[:force]
          elsif not File.directory?(dir.p)
            raise Errno::ENOTDIR, "not a directory -- #{dir}"  unless o[:force]
          else
            rm_r *Pa.glob2("#{dir}/*", :dotmatch => true)
          end
        }
      end

      def empty_dir_f(*dirs)
        dirs, o = Util.extract_options(dirs)
        o[:force] = true
        empty_dir *dirs, o
      end
      
      # rm recusive, rm both file and directory
      #
      # @see rm
      # @return [nil]
      def rm_r(*paths)
        paths, o = Util.extract_options(paths)
        puts "rm -r #{path.join(" ")}" if o[:show_cmd]
        Pa.glob(*paths){ |pa|
          puts "rm -r #{pa.p}" if o[:verbose]
          File.directory?(pa.p)  ? _rmdir(pa) : File.delete(pa.p)
        }
      end
      alias rm_rf rm_r

      # rm_if(path) if condition is true
      #
      # @example
      #   Pa.rm_if '/tmp/**/*.rb' do |pa|
      #     pa.name == 'old'
      #   end
      #
      # @param [String] *paths support globbing
      # @yield [path]
      # @yieldparam [Pa] path
      # @yieldreturn [Boolean] rm_r path if true
      # @return [nil]
      def rm_if(*paths, &blk)
        paths, o = Util.extract_options(paths)
        Pa.glob(*paths) do |pa|
          rm_r pa, o if blk.call(pa)
        end
      end

      # copy
      #
      # cp file dir
      #  cp 'a', 'dir' #=> dir/a 
      #  cp 'a', 'dir/a' #=> dir/a
      #
      # cp file1 file2 .. dir
      #  cp ['a','b'], 'dir' #=> dir/a dir/b
      #
      # @example
      #  cp '*', 'dir' do |src, dest, o|
      #    skip if src.name=~'.o$'
      #    dest.replace 'dirc' if src.name=="foo"
      #    yield  # use yield to do the actuactal cp work
      #  end
      #
      # default: preverse mode, not owner.
      #
      # @overload cp(src_s, dest, o)
      #   @param [Array<String>, String] src_s support globbing
      #   @param [String,Pa] dest
      #   @param [Hash] o option
      #   @option o [Boolean] :mkdir mkdir(dest) if dest not exists.
      #   @option o [Boolean] :verbose puts cmd when execute
      #   @option o [Boolean] :show_cmd puts cmd
      #   @option o [Boolean] :folsymlink follow symlink
      #   @option o [Boolean] :force force dest file if dest is a file
      #   @option o [Boolean] :special special copy, when cp a directory, only mkdir, not cp the directory's content, usefull in Pa.each_r
      #   @return [nil]
      # @overload cp(src_s, dest, o)
      #   @yield [src,dest,o]
      #   @return [nil]
      def cp(src_s, dest, o={}, &blk)
        srcs = Pa.glob(*Util.wrap_array(src_s)).map{|v| v.path}
        dest = Pa.get(dest)
        puts "cp #{srcs.join(" ")} #{dest}" if o[:show_cmd]

        if o[:mkdir] and (not File.exists?(dest))
          Pa.mkdir dest
        end

        # cp file1 file2 .. dir
        if srcs.size>1 and (not File.directory?(dest))
          raise Errno::ENOTDIR, "dest not a directory when cp more than one src -- #{dest}"  
        end

        srcs.each do |src|
          dest1 = File.directory?(dest) ? File.join(dest, File.basename(src)) : dest

          if blk
            blk.call src, dest1, o, proc{_copy(src, dest1, o)}
          else
            _copy src, dest1, o
          end

        end
      end

      def cp_f(src_s, dest, o={}, &blk)
        o[:force] = true
        cp src_s, dest, o, &blk
      end

      # move, use rename for same device. and cp for cross device.
      # @see cp
      #
      # @param [Hash] o option
      # @option o [Boolean] :verbose verbose mode
      # @option o [Boolean] :show_cmd puts cmd
      # @option o [Boolean] :mkdir
      # @option o [Boolean] :fore
      # @return [nil]
      def mv(src_s, dest, o={}, &blk)
        srcs = Pa.glob(*Util.wrap_array(src_s)).map{|v| get(v)}
        dest = get(dest)

        extra_doc = o[:force] ? "-f " : nil
        puts "mv #{extra_doc}#{srcs.join(" ")} #{dest}" if o[:show_cmd]

        if o[:mkdir] and (not File.exists?(dest))
          mkdir dest
        end

        # mv file1 file2 .. dir
        if srcs.size>1 and (not File.directory?(dest))
          raise Errno::ENOTDIR, "dest not a directory when mv more than one src -- #{dest}"  
        end

        srcs.each do |src|
          dest1 = File.directory?(dest) ? File.join(dest, File.basename(src)) : dest

          if blk
            blk.call src, dest1, o, proc{_move(src, dest1, o)}
          else
            _move src, dest1, o
          end

        end
      end

      def mv_f(src_s, dest, o={}, &blk)
        o[:force] = true
        mv src_s, dest, o, &blk
      end

      # I'm recusive
      #
      # _move "file", "dir/file"
      #
      # @param [String] src
      # @param [String] dest
      def _move(src, dest, o)
        raise Errno::EEXIST, "dest exists -- #{dest}" if File.exists?(dest) and (not o[:force])

        # :force. mv "dir", "dira" and 'dira' exists and is a directory. 
        if File.exists?(dest) and File.directory?(dest)
            ls(src) { |pa|
              dest1 = File.join(dest, File.basename(pa.p))
              _move pa.p, dest1, o
            }
            Pa.rm_r src

        else
          begin
            Pa.rm_r dest if o[:force] and File.exists?(dest)
            puts "rename #{src} #{dest}" if o[:verbose]
            File.rename(src, dest)
          rescue Errno::EXDEV # cross-device
            _copy(src, dest, o)
            Pa.rm_r src
          end

        end
      end # def _move

      # @param [Array<String,Pa>] paths
      def _touch(paths, o)
        o[:mode] ||= 0644
        paths.map!{|v|get(v)}
        extra_doc = o[:force] ? "-f " : nil
        puts "touch #{extra_doc}#{paths.join(" ")}" if o[:show_cmd]
        paths.each {|p|
          puts "touch #{extra_doc}#{p}" if o[:verbose]

          if File.exists?(p) 
            o[:force] ? next : raise(Errno::EEXIST, "File exist -- #{p}")
          end

          mkdir(File.dirname(p)) if o[:mkdir]

          if Util.windows?
            # windows BUG. must f.write("") then file can be deleted.
            File.open(p, "w"){|f| f.write("")}  # windows need f.write so that it can be delete.
            File.chmod(o[:mode], p) # jruby can't use File#chmod
          else
            File.open(p, "w"){}
            File.chmod(o[:mode], p) 
          end
        }
      end

      # @param [Array,String,#path] src_s
      # @param [String,#path] dest
      #
      def _ln(method, src_s, dest, o={})
        srcs = Util.wrap_array(src_s)
        dest = get(dest)
        extra_doc = "" 
        extra_doc << (method==:symlink ? "-s " : "")
        extra_doc << (o[:force] ? "-f " : "")
        puts "ln #{extra_doc}#{srcs.join(" ")} #{dest}" if o[:show_cmd]

        Pa.glob(*srcs) {|src|
          src = get(src)
          dest = File.join(dest, File.basename(src)) if File.directory?(dest)

          if File.exists?(dest) 
            if o[:force]
              Pa.rm_r(dest)
            else
              raise Errno::EEXIST, "dest exists -- #{dest}"
            end
          end

          puts "ln #{extra_doc}#{src} #{dest}" if o[:verbose] 

          # jruby need absolute_path
          if method == :link then
            src, dest = File.absolute_path(src, "."), File.absolute_path(dest, ".") # rbx
          end

          File.send(method, src, dest)
        }	
      end

      def _mkdir(paths, o)
        puts "mkdir #{paths.join(" ")}" if o[:show_cmd]

        o[:mode] ||= 0775
        paths.map!{|v|get(v)}
        paths.each {|p|
          puts "mkdir #{p}" if o[:verbose]

          if File.exists?(p)
            if o[:force] 
              next 
            else 
              raise Errno::EEXIST, "File exist -- #{p}"
            end
          end

          stack = []
          until p == stack.last
            break if File.exists?(p)
            stack << p
            p = File.dirname(p)
          end

          stack.reverse.each do |path|
            Dir.mkdir(path)
            File.chmod(o[:mode], path)
          end
        }
      end

      # <name>.JNBNZG
      def _mktmpname(name=nil, o={})
        o[:tmpdir] ||= Dir.tmpdir
        name ||= $$

        begin
          random = SecureRandom.hex(3).upcase
          path = "#{o[:tmpdir]}/#{name}.#{random}"
        end while File.exists?(path)

        path
      end # def mktmpname

      # I'm recusive 
      # param@ [Pa] path
      def _rmdir(pa, o={})
        return if not File.exists?(pa.p)
        Pa.each(pa) {|pa1|
          File.directory?(pa1.p) ? _rmdir(pa1, o) : File.delete(pa1.p)
        }
        File.directory?(pa.p) ? Dir.rmdir(pa.p) : File.delete(pa.p)
      end

      # I'm recursive 
      #
      # @param [String] src
      # @param [String] dest
      def _copy(src, dest, o={})  
        raise Errno::EEXIST, "dest exists -- #{dest}" if File.exists?(dest) and (not o[:force])

        case type=File.ftype(src)

        when "file", "socket"
          puts "cp #{src} #{dest}" if o[:verbose]
          File.copy_stream(src, dest)

        when "directory"
          begin
            Pa.mkdir dest, :verbose => o[:verbose]
          rescue Errno::EEXIST
          end

          return if o[:special]

          each(src) { |pa|
            _copy(pa.p, File.join(dest, File.basename(pa.p)), o)
          }

        when "link" # symbol link
          if o[:folsymlink] 
            _copy(Pa.readlink(src), dest) 
          else
            Pa.symln(Pa.readlink(src), dest, :force => true, :verbose => o[:verbose])	
          end

        when "unknow"
          raise EUnKnownType, "Can't handle unknow type(#{:type}) -- #{src}"
        end

        # chmod chown utime
        src_stat = o[:folsymlink] ? File.stat(src) : File.lstat(src)
        begin
          File.chmod(src_stat.mode, dest)
          #File.chown(src_stat.uid, src_stat.gid, dest)
          File.utime(src_stat.atime, src_stat.mtime, dest)
        rescue Errno::ENOENT
        end
      end # _copy

      DELEGATE_METHODS.each do |mth|
        class_eval <<-EOF
          def #{mth}(*args, &blk)
            Pa(#{mth}2(*args, &blk))
          end
        EOF
      end
    end
  end
end
