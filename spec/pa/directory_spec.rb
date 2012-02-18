require "spec_helper"
require "fileutils"
require "tmpdir"

class Pa
	class << self
		public :_copy, :_move, :_rmdir, :_mktmpname, :_mkdir, :_touch
	end
end

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

  describe ".tmpdir2" do
    it "works" do
      Pa.tmpdir2.should == Dir.tmpdir
    end
  end

  describe ".tmpdir" do
    it "works" do
      Pa.tmpdir.should == Pa(Dir.tmpdir)
    end
  end

	describe ".glob2" do
    # filea
    # .filea
		before :each do 
			FileUtils.touch %w[filea .filea]
		end

    it "returns 1 items" do
      Pa.glob2("*").should have(1).items
    end

    it "returns 2 items with :dotmatch" do
      Pa.glob2("*", dotmatch: true).should have(2).items
    end

    it "#glob returns Pa instead" do
      Pa.glob("*")[0].should be_an_instance_of Pa
    end
	end

	describe ".each2" do
		# filea .filea filea~ 
		# dira/
		#   dirb/
		#     b
		before :each do 
			FileUtils.mkdir_p %w[dira/dirb]
			FileUtils.touch %w[filea .filea filea~ dira/dirb/b]
		end

		it "works" do
			ret = []
			Pa.each2{|pa| ret << pa}
			ret.sort.should == %w(.filea dira filea filea~)
		end

		it "return a Enumerator when call without block" do
			Pa.each2.should be_an_instance_of Enumerator
		end

		it "raise Errno::ENOENT if path doesn't exists" do
			lambda { Pa.each2("path_doesn't_exits"){} }.should raise_error(Errno::ENOENT)
		end

		it "raise Errno::ENOTDIDR if path isn't a directory" do
			lambda { Pa.each2("filea"){} }.should raise_error(Errno::ENOTDIR)
		end

    it "(:file => true) return path if path is a file." do
      #Pa.each2("filea", :file => true).with_object([]){|(pa),m|m<<pa}.should == %w[filea]
      Pa.each2("filea", :file => true).to_a.should == %w[filea]
    end

		it "(.) return 'foo' not '.foo'" do 
			Pa.each2.to_a.map{|v|v[0]}.sort.should == %w(.filea dira filea filea~)
		end

		it "with :dot => false -> list all files except dot file" do
			Pa.each2(:dot => false).to_a.map{|v|v[0]}.sort.should == %w[dira filea filea~]
		end

    it "with :backup => false" do
      Pa.each2(:backup => false).to_a.map{|v|v[0]}.sort.should == %w[.filea dira filea]
    end

    it "with :absolute => true" do
      b = %w[.filea dira filea filea~].map{|v| File.join(Dir.pwd, v)}
      Pa.each2(:absolute => true).to_a.map{|v|v[0]}.sort.should == b
    end

    it "returns Pa" do
      Pa.each { |pa|
        pa.should be_an_instance_of Pa
        break
      }
    end
	end

  describe ".each" do
		# filea .filea filea~ 
		# dira/
		#   dirb/
		#     b
		before :each do 
			FileUtils.mkdir_p %w[dira/dirb]
			FileUtils.touch %w[filea .filea filea~ dira/dirb/b]
		end

    it "works" do
			ret = []
			Pa.each{|pa| ret << pa.p }
			ret.sort.should == %w(.filea dira filea filea~)
    end

		it "return a Enumerator when call without block" do
			Pa.each.should be_an_instance_of Enumerator
		end
  end

	describe ".each2_r" do
		# filea .filea filea~ 
		# dira/
		#   dirb/
		#     b
		before :each do 
			FileUtils.mkdir_p %w[dira/dirb]
			FileUtils.touch %w[filea .filea filea~ dira/dirb/b]
		end

		it "each2_r -> Enumerator" do
			Pa.each2_r.should be_an_instance_of Enumerator
		 	Pa.each2_r.with_object([]){|(pa,r),m|m<<r}.sort.should == %w[.filea dira dira/dirb dira/dirb/b filea filea~]
		end

    it "with :absolute => true" do
      Pa.each2_r(:absolute => true).to_a[0][0].should == File.join(Dir.pwd, "filea~")
    end


    it "#each_r returns Pa" do
      Pa.each_r { |pa|
        pa.should be_an_instance_of Pa
        break
      }
    end
	end

	describe ".ls2" do
		# filea 
		# dira/
		# 	fileb
		before :each do 
			FileUtils.mkdir_p %w[dira]
			FileUtils.touch %w[filea dira/fileb]
		end

		it "works" do
			Pa.ls2.should == %w[filea dira]
      Pa.ls2(Dir.pwd).should == %w[filea dira]
		end

    it "list multi paths" do
      Pa.ls2(".", "dira").should == %w[filea dira fileb]
    end

    it "with :absolute => true" do
      Pa.ls2(:absolute => true).should == %w[filea dira].map{|v| File.join(Dir.pwd, v)}
    end

		it "call a block" do
			Pa.ls2 { |p, fn| File.directory?(p)  }.should == ["dira"]
		end
  end

  describe ".ls" do
		# filea 
		# dira/
		# 	fileb
		before :each do 
			FileUtils.mkdir_p %w[dira]
			FileUtils.touch %w[filea dira/fileb]
		end

		it "works" do
			Pa.ls.should == %w[filea dira].map{|v|Pa(v)}
      Pa.ls(Dir.pwd).should == %w[filea dira].map{|v|Pa(v)}
		end

    it "list multi paths" do
      Pa.ls(".", "dira").should == %w[filea dira fileb].map{|v|Pa(v)}
    end

    it "with :absolute => true" do
      Pa.ls(:absolute => true).should == %w[filea dira].map{|v|Pa(File.join(Dir.pwd, v))}
    end

		it "call a block" do
			Pa.ls{|p, fn| p.directory? }.should == %w[dira].map{|v|Pa(v)}
		end
  end

  describe "instance DELEGATE_METHODS" do
    it "works" do
      Pa.should_receive(:each2).with("x", 1, 2)

      Pa("x").each2(1,2)
    end
  end
end
