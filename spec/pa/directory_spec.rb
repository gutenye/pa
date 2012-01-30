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
		Dir.chdir(@tmpdir)
	end

	after :all do
		Dir.chdir(@curdir)
		FileUtils.rm_r @tmpdir
	end

  describe ".tmpdir2" do
    it "works" do
      Pa.tmpdir2.should == Dir.tmpdir
    end
  end

	describe ".glob2" do
		before(:each) do 
			@files = %w(fa .fa)
			FileUtils.touch(@files)
		end
		after(:each) do 
			FileUtils.rm @files
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
		# fa .fa fa~ 
		# dira/
		#   dirb/
		#     b
		before(:each) do 
			@dirs = %w(dira/dirb)
			@files = %w(fa .fa fa~ dira/dirb/b)
			FileUtils.mkdir_p(@dirs)
			FileUtils.touch(@files)
		end
		after(:each) do 
			FileUtils.rm @files
			FileUtils.rm_r @dirs
		end

		it "works" do
			ret = []
			Pa.each2{|pa| ret << pa}
			ret.sort.should == %w(.fa dira fa fa~)
		end

		it "return a Enumerator when call without block" do
			Pa.each2.should be_an_instance_of Enumerator
		end

		it "raise Errno::ENOENT if path doesn't exists" do
			lambda { Pa.each2("path_doesn't_exits"){} }.should raise_error(Errno::ENOENT)
		end

		it "raise Errno::ENOTDIDR if path isn't a directory" do
			lambda { Pa.each2("fa"){} }.should raise_error(Errno::ENOTDIR)
		end

		it "each2(.) return 'foo' not '.foo'" do 
			Pa.each2.with_object([]){|(pa),m| m<<pa}.sort.should == %w(.fa dira fa fa~)
		end

		it ".each2 with :dot => false -> list all files except dot file" do
			Pa.each2(:dot => false).with_object([]){|(pa),m|m<<pa}.sort.should == %w[dira fa fa~]
		end

    it ".each2 with :backup => false" do
      Pa.each2(:backup => false).with_object([]){|(pa),m|m<<pa}.sort.should == %w[.fa dira fa]
    end

    it ".each2 with :absolute => true" do
      b = %w[.fa dira fa fa~].map{|v| File.join(Dir.pwd, v)}
      Pa.each2(:absolute => true).with_object([]){|(pa),m|m<<pa}.sort.should == b
    end

    it "each returns Pa" do
      Pa.each { |pa|
        pa.should be_an_instance_of Pa
        break
      }
    end
	end

  describe ".each" do
		# fa .fa fa~ 
		# dira/
		#   dirb/
		#     b
		before(:each) do 
			@dirs = %w(dira/dirb)
			@files = %w(fa .fa fa~ dira/dirb/b)
			FileUtils.mkdir_p(@dirs)
			FileUtils.touch(@files)
		end

		after(:each) do 
			FileUtils.rm @files
			FileUtils.rm_r @dirs
		end

    it "works" do
			ret = []
			Pa.each{|pa| ret << pa.p }
			ret.sort.should == %w(.fa dira fa fa~)
    end

		it "return a Enumerator when call without block" do
			Pa.each.should be_an_instance_of Enumerator
		end
  end

	describe ".each2_r" do
		# fa .fa fa~ 
		# dira/
		#   dirb/
		#     b
		before(:each) do 
			@dirs = %w(dira/dirb)
			@files = %w(fa .fa fa~ dira/dirb/b)
			FileUtils.mkdir_p(@dirs)
			FileUtils.touch(@files)
		end
		after(:each) do 
			FileUtils.rm @files
			FileUtils.rm_r @dirs
		end

		it "each2_r -> Enumerator" do
			Pa.each2_r.should be_an_instance_of Enumerator
		 	Pa.each2_r.with_object([]){|(pa,r),m|m<<r}.sort.should == %w[.fa dira dira/dirb dira/dirb/b fa fa~]
		end

    it "with :absolute => true" do
      Pa.each2_r(:absolute => true).to_a[0][0].should == File.join(Dir.pwd, "fa~")
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
		before(:each) do 
			@dirs = %w(dira)
			@files = %w(filea dira/fileb)
			FileUtils.mkdir_p(@dirs)
			FileUtils.touch(@files)
		end
		after(:each) do 
			FileUtils.rm @files
			FileUtils.rm_r @dirs
		end

		it "works" do
			Pa.ls2.should == %w[filea dira]
      Pa.ls2(Dir.pwd).should == %w[filea dira]
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
		before(:each) do 
			@dirs = %w(dira)
			@files = %w(filea dira/fileb)
			FileUtils.mkdir_p(@dirs)
			FileUtils.touch(@files)
		end
		after(:each) do 
			FileUtils.rm @files
			FileUtils.rm_r @dirs
		end

		it "works" do
			Pa.ls.should == %w[filea dira].map{|v| Pa(v)}
      Pa.ls(Dir.pwd).should == %w[filea dira].map{|v| Pa(v)}
		end

    it "with :absolute => true" do
      Pa.ls(:absolute => true).should == %w[filea dira].map{|v| Pa(File.join(Dir.pwd, v))}
    end

		it "call a block" do
			Pa.ls{|p, fn| p.directory? }.should == %w[dira].map{|v| Pa(v)}
		end
  end

  describe "instance DELEGATE_METHODS" do
    it "works" do
      Pa.should_receive(:each2).with("x", 1, 2)

      Pa("x").each2(1,2)
    end
  end
end
