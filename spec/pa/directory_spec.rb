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

    it "remove . .." do
      Pa.glob2(".*").should have(1).items
      Pa.glob2("#{@tmpdir}/.*").should have(1).items
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

    it "(:base_dir => x) to build clean path" do
      Pa.each2("dira").to_a.map{|v|v[0]}.should == %w[dira/dirb]
      Pa.each2("dirb", :base_dir => "dira").to_a.map{|v|v[0]}.should == %w[dirb/b]
      Pa.each2("dirb", :base_dir => Pa("dira")).to_a.map{|v|v[0]}.should == %w[dirb/b]
    end

    it "yields {|path, abs, fname, err, rea|}" do
      Pa.each2("dira").to_a.sort[0].should == ["dira/dirb", File.join(Dir.pwd, "dira/dirb"), "dirb", nil, "dira/dirb"]
      Pa.each2("dirb", :base_dir => "dira").to_a.sort[0].should == ["dirb/b", File.join(Dir.pwd, "dira/dirb/b"), "b", nil, "dira/dirb/b"]
    end

		it "list a directory" do
			Pa.each2.to_a.map{|v|v[0]}.sort.should == %w[.filea dira filea filea~]
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
      Pa.each2("filea", :file => true).to_a[0][0].should == "filea"
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

    it "=> Enumerator when call without any arguments" do
			Pa.each2_r.should be_an_instance_of Enumerator
		end

    it "list directory recursive" do
		 	Pa.each2_r.map{|v,|v}.sort.should == %w[.filea dira dira/dirb dira/dirb/b filea filea~]
    end

    it "(:base_dir => x) to build clean path" do
      Pa.each2_r("dira").to_a.map{|v|v[0]}.should == %w[dira/dirb dira/dirb/b]
      Pa.each2_r(".", :base_dir => "dira").to_a.map{|v|v[0]}.should == %w[dirb dirb/b]
      Pa.each2_r(".", :base_dir => Pa("dira")).to_a.map{|v|v[0]}.should == %w[dirb dirb/b]
    end
	end

	describe ".each_r" do
		# filea .filea filea~ 
		# dira/
		#   dirb/
		#     b
		before :each do 
			FileUtils.mkdir_p %w[dira/dirb]
			FileUtils.touch %w[filea .filea filea~ dira/dirb/b]
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
    # dirb/
    #   dirb1/
    #     fileb1
		before :each do 
			FileUtils.mkdir_p %w[dira dirb/dirb1]
			FileUtils.touch %w[filea dira/fileb dirb/dirb1/fileb1]
		end

		it "works" do
			Pa.ls2.sort.should == %w[dira dirb filea]
      Pa.ls2("dira").sort.should == %w[fileb]
		end

    it "list multi paths" do
      Pa.ls2("dira", "dirb").should == %w[fileb dirb1]
    end

    it "(:absolute => true) returns absolute path" do
      Pa.ls2("dira", :absolute => true).should == [File.join(Dir.pwd, "dira/fileb")]
    end

    it %~(:include => true) returns "<path>/foo"~ do
      Pa.ls2("dira", :include => true).should == %w[dira/fileb]
    end

    it "(:base_dir => x)" do
      Pa.ls2("dirb1", :base_dir => "dirb").should == %w[fileb1]
      Pa.ls2("dirb1", :base_dir => "dirb", :include => true).should == %w[dirb1/fileb1]
    end

		it "call a block returns filtered result" do
			Pa.ls2 {|p| File.directory?(p)}.sort.should == %w[dira dirb]
		end
  end

	describe ".ls2_r" do
		# filea 
		# dira/
		# 	fileb
    # dirb/
    #   dirb1/
    #     fileb1
		before :each do 
			FileUtils.mkdir_p %w[dira dirb/dirb1]
			FileUtils.touch %w[filea dira/fileb dirb/dirb1/fileb1]
		end

		it "works" do
			Pa.ls2_r.sort.should == %w[dira dira/fileb dirb dirb/dirb1 dirb/dirb1/fileb1 filea]
      Pa.ls2_r("dirb").sort.should == %w[dirb1 dirb1/fileb1]
		end

    it "list multi paths" do
      Pa.ls2_r("dira", "dirb").should == %w[fileb dirb1 dirb1/fileb1]
    end

    it "(:absolute => true) returns absolute path" do
      Pa.ls2_r("dirb", :absolute => true).should == %w[dirb/dirb1 dirb/dirb1/fileb1].map{|v|File.join(Dir.pwd, v)}
    end

    it %~(:include => true) returns "<path>/foo"~ do
      Pa.ls2_r("dirb", :include => true).should == %w[dirb/dirb1 dirb/dirb1/fileb1]
    end

    it "(:base_dir => x)" do
      Pa.ls2_r("dirb1", :base_dir => "dirb").should == %w[fileb1]
      Pa.ls2_r("dirb1", :base_dir => "dirb", :include => true).should == %w[dirb1/fileb1]
    end

		it "call a block returns filtered result" do
			Pa.ls2_r {|p, fn| File.directory?(p)}.sort.should == %w[dira dirb dirb/dirb1]
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
			Pa.ls.sort.should == %w[filea dira].map{|v|Pa(v)}.sort
      Pa.ls(Dir.pwd).sort.should == %w[filea dira].map{|v|Pa(v)}.sort
		end

    it "list multi paths" do
      Pa.ls(".", "dira").sort.should == %w[filea dira fileb].map{|v|Pa(v)}.sort
    end

    it "with :absolute => true" do
      Pa.ls(:absolute => true).sort.should == %w[filea dira].map{|v|Pa(File.join(Dir.pwd, v))}.sort
    end

		it "call a block" do
			Pa.ls{|p, fn| p.directory? }.sort.should == %w[dira].map{|v|Pa(v)}.sort
		end
  end

  describe "instance DELEGATE_METHODS" do
    it "works" do
      Pa.should_receive(:each2).with("x", 1, 2)

      Pa("x").each2(1,2)
    end
  end
end
