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

	after(:all) do
		Dir.chdir(@curdir)
		FileUtils.rm_r @tmpdir
	end

  describe ".tmpdir2" do
    it "works" do
      Pa.tmpdir2.should == Dir.tmpdir
    end
  end

	describe "#glob2" do
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

	describe "#each2" do
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

		it "runs on" do
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

		it "each2(nodot: true) -> list all files except dot file" do
			Pa.each2(nodot: true).with_object([]){|(pa),m|m<<pa}.sort.should == %w(dira fa fa~)
		end

    it "each returns Pa" do
      Pa.each { |pa|
        pa.should be_an_instance_of Pa
        break
      }
    end
	end

	describe "#each2_r" do
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
		 	Pa.each2_r.with_object([]){|(pa,r),m|m<<r}.sort.should == %w(.fa dira dira/dirb dira/dirb/b fa fa~)
		end

    it "#each_r returns Pa" do
      Pa.each_r { |pa|
        pa.should be_an_instance_of Pa
        break
      }
    end
	end

	describe "#ls2" do
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

		it "runs ok -> Array" do
			Pa.ls2.should == ["filea", "dira"]
		end

		it "call a block" do
			Pa.ls2 { |pa, fname| File.directory?(pa)  }.should == ["dira"]
		end

    it "#ls returns string" do
      Pa.ls[0].should be_an_instance_of String
    end
	end
end

