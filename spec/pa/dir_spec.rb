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

	describe "#glob" do
		before(:each) do 
			@files = %w(fa .fa)
			FileUtils.touch(@files)
		end
		after(:each) do 
			FileUtils.rm @files
		end

		context "call without any option" do
			it "returns 1 items" do
				Pa.glob("*").should have(1).items
			end
		end

		context "call with :dotmatch option" do
			it "returns 2 items" do
				Pa.glob("*", dotmatch: true).should have(2).items
			end
		end
	end

	describe "#each" do
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
			Pa.each{|pa| ret << pa.fname}
			ret.sort.should == %w(.fa dira fa fa~)
		end

		it "return a Enumerator when call without block" do
			Pa.each.should be_an_instance_of Enumerator
		end

		it "raise Errno::ENOENT if path doesn't exists" do
			lambda { Pa.each("path_doesn't_exits"){} }.should raise_error(Errno::ENOENT)
		end

		it "raise Errno::ENOTDIDR if path isn't a directory" do
			lambda { Pa.each("fa"){} }.should raise_error(Errno::ENOTDIR)
		end

		it "each(.) return 'foo' not '.foo'" do 
			Pa.each.with_object([]){|pa,m| m<<pa.p}.sort.should == %w(.fa dira fa fa~)
		end

		it "each(nodot: true) -> list all files except dot file" do
			Pa.each(nodot: true).with_object([]){|pa,m|m<<pa.b}.sort.should == %w(dira fa fa~)
		end

	end

	describe "#each_r" do
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

		it "each_r -> Enumerator" do
			Pa.each_r.should be_an_instance_of Enumerator
		 	Pa.each_r.with_object([]){|(pa,r),m|m<<r}.sort.should == %w(.fa dira dira/dirb dira/dirb/b fa fa~)
		end
	end


	describe "#ls" do
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
			Pa.ls.should == ["filea", "dira"]
		end

		it "call a block" do
			Pa.ls { |pa, fname| pa.directory?  }.should == ["dira"]
		end
	end


end
