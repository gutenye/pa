require "spec_helper"
require "fileutils"
require "tmpdir"

public_all_methods Pa::Cmd::ClassMethods

describe Pa do
	before :all do
		@curdir = Dir.pwd
		@tmpdir = Dir.mktmpdir
		Dir.chdir @tmpdir
	end

	after :all do
		Dir.chdir @curdir
		FileUtils.rm_r @tmpdir
	end

  # clean up directory after each run
  after :each do
    FileUtils.rm_r Dir.glob("*", File::FNM_DOTMATCH)-%w[. ..]
  end

  describe "#home2" do
    it "works" do
      Pa.home2.should == Dir.home
    end
  end

  describe "#_ln" do
    # _lna
    before :each do
      FileUtils.touch %w[_lna]
    end

    it "works" do
      output = capture :stdout do
        Pa._ln(:link, "_lna", "_lnb", :verbose => true) 
      end

      output.should == "ln _lna _lnb\n"
      File.identical?("_lna", "_lnb").should be_true
    end
  end

  describe "#ln" do
    # file1
    # file2
    before :each do
      FileUtils.touch %w[file1 file2]
    end

    it "works" do
      Pa.ln("file1", "lna")
      File.identical?("file1", "lna").should be_true
    end

    it "raises Errno::EEXIST" do
      lambda{ Pa.ln("file1", "file2") }.should raise_error(Errno::EEXIST)
    end

    it "doesn't raise Errno::EEXIST with :force" do
      lambda{ Pa.ln("file1", "file2", :force => true)  }.should_not raise_error(Errno::EEXIST) 
      File.identical?("file1", "file2").should be_true
    end
  end

  describe "#symln" do
    # file1
    # file2
    before :each do
      FileUtils.touch %w[file1 file2]
    end

    it "works" do
      Pa.symln("file1", "syma")
      File.symlink?("syma").should be_true
    end

    it "raises Errno::EEXIST" do
      lambda{ Pa.symln("file1", "file2") }.should raise_error(Errno::EEXIST)
    end

    it "doesn't raise Errno::EEXIST with :force" do
      lambda{ Pa.symln("file1", "file2", :force => true) }.should_not raise_error(Errno::EEXIST) 
      File.symlink?("file2").should be_true
      File.readlink("file2").should == "file1"
    end
  end

  describe "#readlink" do
    # syma -> file1
    before :each do
      FileUtils.touch %w[file1]
      File.symlink "file1", "syma"
    end

    it "works" do
      Pa.readlink("syma").should == "file1"
      Pa.readlink(Pa("syma")).should == "file1"
    end
  end

  describe "#cd" do
    # dir1/
    before :each do
      FileUtils.mkdir_p %w[dir1]
    end
    
    after :each do
      Dir.chdir @tmpdir
    end

    it "works" do
      Pa.cd("dir1")
      Dir.pwd.should == File.join(@tmpdir, "dir1")
    end
  end

  describe "#chroot" do
    it "works" do
      Dir.should_receive(:chroot).with("dir1")
      Pa.chroot "dir1"

      Dir.should_receive(:chroot).with("dir2")
      Pa.chroot Pa("dir2")
    end
  end

  describe "#_touch" do
    it "works" do
      Pa._touch ["file1", Pa("file2")], {}

      File.exists?("file1").should be_true
      File.exists?("file2").should be_true
    end
  end

  describe "#touch" do
    it "works" do
      Pa.touch("file1", "file2")

      File.exists?("file1").should be_true
      File.exists?("file2").should be_true
    end
  end

  describe "#touch" do
    # file1
    # file2
    before :each do
      FileUtils.touch %w[file1 file2]
    end

    it "works" do
      Pa.touch_f("file1", "file2")

      File.exists?("file1").should be_true
      File.exists?("file2").should be_true
    end
  end

	describe "#mkdir" do
    # dir1/dira
    before :each do
      FileUtils.mkdir_p %w[dir1/dira]
    end

		it "works" do
			Pa.mkdir("dir2/dirb")
			File.exists?("dir2/dirb").should be_true
		end

    it "raise Errno::EEXIST" do
      lambda{ Pa.mkdir("dir1/dira") }.should raise_error(Errno::EEXIST)
    end

    it "doesn't raise Errno::EEXIST with :force" do
      lambda{ Pa.mkdir("dir1/dira", :force) }.should_not raise_error(Errno::EEXIST)
    end
	end

  describe "#_mktmpname" do
    it "works" do
      path = Pa._mktmpname("foo", :tmpdir => "guten")

      path.should =~ %r~guten/foo\..{6}~
    end
  end

  describe "#mktmpdir" do
    it "works" do
      Dir.should_receive(:mkdir)

      path = Pa.mktmpdir("foo")

      path.should =~ %r~#{Regexp.escape(Dir.tmpdir)}/foo~
    end
  end

  describe "#mktmpfile2" do
    it "works" do
      path = Pa.mktmpfile2 :tmpdir => "foo"

      path.should =~ %r~foo/#{$$}~
    end
  end

  describe "#mktmpfile" do
    it "works" do
      path = Pa.mktmpfile

      path.should be_an_instance_of(Pa)
    end
  end

	describe "#_rmdir" do
		# dir/
		#   a
		#  dir1/
		#    aa
		before :each do	
			FileUtils.mkdir_p %w[dir/dir1]
			FileUtils.touch %w[dir/a dir/dir1/aa]
		end

		it "remove directory" do
			Pa._rmdir Pa("dir")
			File.exists?("dir").should be_false
		end
	end

  describe "#rm" do
    # rm family
    # a
    # dir/ 
    #   dir1/
    #   a 
    before :each do
      FileUtils.mkdir_p %w[dir/dir1]
      FileUtils.touch %w[a dir/a]
    end

    it "remove file" do
      Pa.rm "a"
      File.exists?("a").should be_false
    end

    it "raises Errno::EISDIR" do
      lambda{ Pa.rm("dir") }.should raise_error(Errno::EISDIR)
    end

    it "doens't raises Errno::EISDIR with :force" do
      lambda{ Pa.rm("dir", :force => true) }.should_not raise_error(Errno::EISDIR)
    end
  end

  describe "#rmdir" do
    # rm family
    # a
    # dir/ 
    #   dir1/
    #   a 
    before :each do
      FileUtils.mkdir_p %w[dir/dir1]
      FileUtils.touch %w[a dir/a]
    end

    it "remove directory" do
      Pa.rmdir "dir"
      File.exists?("dir").should be_false
    end

    it "raises Errno::ENOTDIR" do
      lambda{ Pa.rmdir("a") }.should raise_error(Errno::ENOTDIR)
    end

    it "doesn't raise Errno::ENOTDIR with :force" do
      lambda{ Pa.rmdir_r("a", :force => true) }.should_not raise_error(Errno::ENOTDIR) 
    end
  end

  describe "#empty_dir" do
    # a
    # dir/ 
    #   dir1/
    #   a 
    before :each do
      FileUtils.mkdir_p %w[dir/dir1]
      FileUtils.touch %w[a dir/a]
    end

    it "empty a directory" do
      Pa.empty_dir "dir"
      Dir.entries("dir").should == %w[. ..]
    end

    it "raises Errno::ENOTDIR" do
      lambda{ Pa.empty_dir("a") }.should raise_error(Errno::ENOTDIR)
    end

    it "doesn't raise Errno::ENOTDIR with :force" do
      lambda{ Pa.empty_dir("a", :force => true) }.should_not raise_error(Errno::ENOTDIR)
    end

    it "raises Errno::ENOENT" do
      lambda{ Pa.empty_dir "ENOENT" }.should raise_error(Errno::ENOENT)
    end

    it "doesn't raise Errno::ENOENT with :force" do
      lambda{ Pa.empty_dir("ENOENT", :force => true) }.should_not raise_error(Errno::ENOENT)
    end
  end

  describe "#rm_r" do
    # rm family
    # a
    # dir/ 
    #   dir1/
    #   a 
    before :each do
      FileUtils.mkdir_p %w[dir/dir1]
      FileUtils.touch %w[a dir/a]
    end

    it "remove both file and directory" do
      Pa.rm "a"
      File.exists?("a").should be_false
      Pa.rm_r "dir"
      File.exists?("dir").should be_false
    end
  end

  describe "#rm_if" do
    # rm family
    # a
    # dir/ 
    #   dir1/
    #   a 
    before :each do
      FileUtils.mkdir_p %w[dir/dir1]
      FileUtils.touch %w[a dir/a]
    end

    it "remove if condition" do
      Pa.rm_if(".") { |pa|
        next if pa.p=="a"
        yield if pa.b=="a"
      }

    File.exists?("a").should be_true 
    File.exists?("dir/dir1/a").should be_false
    end
  end

	describe "#_copy" do
    # rm family
    # a
    # dir/ 
    #   dir1/
    #   a 
    before :each do
      FileUtils.mkdir_p %w[dir/dir1]
      FileUtils.touch %w[a dir/a]
    end

		# a symfile
		# ab
		# ac
		# dir/ 
		#   b   # guten
		#   dir1/
		#     c
		# destdir/
		#   b  # tag
		#   dir/ 
		before :each do
			FileUtils.mkdir_p %w[dir/dir1 destdir/dir]
			FileUtils.touch %w[a ab ac dir/b dir/dir1/c destdir/dir/b]
			File.symlink "a", "symfile"
			open("dir/b", "w"){|f|f.write "guten"}
			open("destdir/dir/b", "w"){|f|f.write "tag"}
		end

		it "_copy file" do
			Pa._copy 'a', 'b'
			File.exists?('b').should be_true
		end

		it "_copy directory" do
			Pa._copy 'dir', 'dirc'
			Dir.entries('dirc').sort.should == Dir.entries('dir').sort
		end

		context "with :symlink" do
			it "_copy" do
				Pa._copy 'symfile', 'symfile1'
				File.symlink?('symfile1').should be_true
			end

			it "_copy with :folsymlink" do
				Pa._copy 'symfile', 'folsymlink', folsymlink:true
				File.symlink?('folsymlink').should be_false
				File.file?('folsymlink').should be_true
			end

		end

		context "with :mkdir" do
			it "_copy with :mkdir => false" do
				lambda{Pa.cp "a", "destdir/mkdir/dir"}.should raise_error(Errno::ENOENT)
			end

			it "_copy with :mkdir => true" do
				lambda{Pa.cp "a", "destdir/mkdir/dir", mkdir:true}.should_not raise_error(Errno::ENOENT)
				File.exists?("destdir/mkdir/dir/a").should be_true
			end

			it "_copy with :mkdir => true" do
				lambda{Pa.cp "a", "destdir/mkdir1", mkdir:true}.should_not raise_error(Errno::ENOENT)
				File.exists?("destdir/mkdir1/a").should be_true
			end
		end

    it "_copy with :force => false" do
      File.open("destdir/overwrite","w"){|f|f.write("")}
      lambda{Pa.cp "a", "destdir/overwrite"}.should raise_error(Errno::EEXIST)
    end

    it "_copy with :force => true" do
      lambda{Pa.cp "a", "destdir/overwrite", force:true}.should_not raise_error(Errno::EEXIST)
    end

		it "_copy with :normal => true" do
			Pa._copy 'dir', 'dir_normal', special: true
			dir_empty = (Dir.entries('dir_normal').length==2)
			dir_empty.should be_true
		end
	end

	describe "#cp" do
    # file1 
    # file2
    # file3
    # dir1/

    before :each do
      FileUtils.mkdir_p %w[dir1]
      FileUtils.touch %w[file1 file2 file3]
    end

		it "cp file destdir/file" do
			Pa.cp "file1", "dir1/file2" 
			File.exists?("dir1/file2").should be_true
		end

		it "cp file destdir/" do
			Pa.cp "file1", "dir1"
			File.exists?("dir1/file1").should be_true
		end

		it "cp file1 file2 .. dest_file" do
			lambda{Pa.cp(%w[file1 file2], "file3")}.should raise_error(Errno::ENOTDIR)
		end

		it "cp file1 file2 .. destdir/" do
			Pa.cp %w[file1 file2], "dir1"
			File.exists?("dir1/file1").should be_true
			File.exists?("dir1/file2").should be_true
		end
	end
	
	describe "#_move" do
		# a
		# dir/ b  
		before :each do
			FileUtils.mkdir_p %w[dir]
			FileUtils.touch %w[a dir/b]
		end

		it "mv a dir/a" do
			ino = File.stat('a').ino
			Pa._move "a", "dir/a", {}
			File.stat('dir/a').ino.should == ino
			File.exists?("a").should be_false
		end
		
		context "with :force" do
			it "mv a dir/b" do
				lambda{Pa._move "a", "dir/b", {}}.should raise_error Errno::EEXIST
			end

			it "mv a dir/b :force" do
				ino = File.stat('a').ino
				Pa._move "a", "dir/b", force:true
				File.stat("dir/b").ino.should == ino
			end
		end

	end

	describe "#mv" do
		# file1 with foo
    # file2
    # file3
		# dir1/ 
    #   filea
    # dir2/
    #  dir1/
		before :each do
			FileUtils.mkdir_p %w[dir]
			FileUtils.touch %w[a b c dir/aa]

			FileUtils.mkdir_p %w[dir1 dir2/dir1]
			FileUtils.touch %w[file1 file2 file3 dir1/filea]
      open("file1", "w") {|f| f.write("foo")}
		end

		it "mv file1 dir1" do
			Pa.mv "file1", "dir1"
			File.exists?("dir1/file1").should be_true
		end

		it "mv file1 file2 .. dir/" do
			Pa.mv %w(a b), "dir"
			File.exists?("dir/a").should be_true
			File.exists?("dir/b").should be_true
		end

    it "raises dest Errno::ENOTDIR" do
      lambda{ Pa.mv(%w[file1 file2], "file3") }.should raise_error(Errno::ENOTDIR)
    end

		it "raises Errno::EEXIST" do 
			lambda{ Pa.mv("file1", "file2") }.should raise_error(Errno::EEXIST)
      lambda{ Pa.mv("dir1", "dir2")  }.should raise_error(Errno::EEXIST)
		end

    it "doesn't raise Errno::ENOTDIR with :force" do
      lambda{ Pa.mv("file1", "file2", :force => true) }.should_not raise_error(Errno::EEXIST)
      File.read("file2").should == "foo"

      lambda{ Pa.mv("dir1", "dir2", :force => true) }.should_not raise_error(Errno::EEXIST)
      File.exists?("dir2/dir1/filea").should be_true
		end
	end

  describe "class DELEGATE_METHODS" do
    it "works" do
      Pa.stub(:home2) { "/home/foo" } 
      Pa.home.should == Pa("/home/foo")

      Pa.should_receive(:home2).with(1, 2)
      Pa.home(1, 2)
    end
  end
end
