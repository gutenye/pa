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

    DELEGATE_CLASS_METHODS = [:pwd, :dir, :expand, :real, :parent, 
      :relative_to, :shorten, :delete_ext, :add_ext ]

    module ClassMethods
      # Return current work directory
      #
      # @return [String] path
      def pwd2
        Dir.getwd 
      end

      # Is path an absolute path ?
      #
      # @param [String,Pa] path
      # @return [Boolean]
      def absolute?(path) 
        p = get(path) 
        File.absolute_path(p, ".") == p  # rbx
      end

      # Is path a dangling symlink?
      #
      # a dangling symlink is a dead symlink.
      #
      # @param [String,Pa] path
      # @return [Boolean]
      def dangling?(path)
        p = get(path)

        if File.symlink?(p)
          src = File.readlink(p)
          not File.exists?(src)
        else
          nil
        end
      end

      # Alias from File.expand_path
      #
      # @param [String,Pa] path
      # @return [String]
      def expand2(name, dir=".") 
        File.expand_path(get(name), dir) 
      end

      # Alias from Filel.realpath
      #
      # @param [String, Pa] path
      # @return [String]
      def real2(name, dir=".")
        File.realpath(get(name), dir)
      end

      # Path relative_to? dir
      #
      # @example
      #
      #   Pa.relative_to?("/home/foo", "/home")  -> true
      #   Pa.relative_to?("/home1/foo", "/home")  -> false
      #
      def relative_to?(path, dir)
        path_parts = Pa.split2(get(path), all: true)
        dir_parts = Pa.split2(get(dir), all: true)

        index = -1
        dir_parts.all? {|part| 
          index += 1
          path_parts[index] == part
        }
      end

      # Delete the head.
      #
      # @example
      #   
      #   Pa.relative_to2("/home/foo", "/home") -> "foo"
      #   Pa.relative_to2("/home/foo", "/home/foo") -> "."
      #   Pa.relative_to2("/home/foo", "/bin") -> "/home/foo"
      #
      #   Pa.relative_to2("/home/foo", "/home/foo/") -> "."
      #   Pa.relative_to2("/home/foo/", "/home/foo") -> "."
      #
      # @return [String]
      def relative_to2(path, dir)
        p = get(path)

        if relative_to?(p, dir)
          path_parts = Pa.split(p, all: true)
          dir_parts = Pa.split(dir, all: true)
          ret = File.join(*path_parts[dir_parts.length..-1])
          ret == "" ? "." : ret
        else
          p
        end
      end

      # Return true if a path has the ext.
      #
      # @example
      #
      #   Pa.has_ext?("foo.txt", ".epub", ".txt")   -> true
      #   Pa.has_ext?("foo", ".txt")       -> false
      #
      def has_ext?(path, *exts)
        exts.include? Pa.ext2(get(path))
      end

      # Delete the tail.
      #
      # @example
      #
      #   Pa.delete_ext2("foo.txt", ".epub", ".txt")      -> "foo"
      #   Pa.delete_ext2("foo", ".txt")          -> "foo"
      #   Pa.delete_ext2("foo.epub", ".txt")     -> "foo.epub"
      #
      def delete_ext2(path, *exts)
        p = get(path)

        exts.each {|ext|
          if has_ext?(p, ext)
            return p[0...p.rindex(ext)]
          end
        }

        p
      end

      # Ensure the tail
      #
      # @example
      #
      #  Pa.add_ext2("foo", ".txt")         -> "foo.txt"
      #  Pa.add_ext2("foo.txt", ".txt")     -> "foo.txt"
      #  Pa.add_ext2("foo.epub", ".txt")    -> "foo.txt.epub"
      #
      def add_ext2(path, ext)
        p = get(path)

        if Pa.ext2(p) == ext
          p
        else
          "#{p}#{ext}"
        end
      end

      # shorten2 a path,
      # convert /home/user/file to ~/file
      #
      # @param [String,Pa] path
      # @return [String]
      def shorten2(path)
        p = get(path)
        home = Pa.home2

        return p if home.empty?

        ret = relative_to2(p, home)

        if ret == p
          p
        else
          ret == "." ? "" : ret
          File.join("~", ret)
        end
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

      DELEGATE_CLASS_METHODS.each { |mth|
        mth2 = "#{mth}2"

        eval <<-EOF
          def #{mth}(*args, &blk)
            Pa(Pa.#{mth2}(*args, &blk))
          end
        EOF
      }


    private

    end

    DELEGATE_METHODS2 = [ :parent2, :delete_ext2, :add_ext2 ]
    DELEGATE_METHODS = [ :parent, :delete_ext, :add_ext]

    DELEGATE_METHODS2.each do |mth2|
      class_eval <<-EOF
        def #{mth2}(*args, &blk)
          Pa.#{mth2}(path, *args, &blk)
        end
      EOF
    end

    DELEGATE_METHODS.each do |mth|
      class_eval <<-EOF
        def #{mth}(*args, &blk)
          Pa(#{mth}2(*args, &blk))
        end
      EOF
    end
  end
end
