require "spec_helper"

describe Pa do
  describe ".absolute?" do
    it "is true if path is a absolute path" do
      Pa.absolute?("/").should == true
    end

    it "is false if path is a relative path" do
      Pa.absolute?(".").should == false
    end
  end

  it ".dir2 => String" do
    Pa.dir2("/home/guten").should be_an_instance_of String
  end

  describe ".dangling?" do 
    it "works" do
      olddir=Dir.pwd
      Dir.chdir("#{$specdir}/data/tmp")

      begin
        File.open("fa", "w"){|f| f.puts "guten" }
        File.symlink("fa", "symlink")
        File.symlink("fb", "dangling")

        Pa.dangling?("symlink").should be_false
        Pa.dangling?("dangling").should be_true
      ensure
        FileUtils.rm_r Dir.glob("*")
        Dir.chdir(olddir)
      end
    end
  end

  describe ".pwd2" do
    olddir = Dir.getwd
    Dir.chdir("/tmp")
    begin
      Pa.pwd2.should == "/tmp"
    ensure
      Dir.chdir(olddir)
    end
  end

  describe ".dir2" do
    it "get a path's directory name" do
      Pa.dir2("/home/guten").should == "/home"
    end
  end

	describe ".base2" do
		it "get name, ext with :ext => true" do
			Pa.base2("/home/foo.bar", ext: true).should == ["foo", "bar"]
		end
	end

  describe ".base" do
    it "works" do
			Pa.base("/home/foo.bar", ext: true).should == [Pa("foo"), "bar"]
    end
  end

  describe ".ext2" do
    it "get a path's extension" do
      Pa.ext2("/home/a.txt").should == "txt"
    end

    it "return nil when don extension" do
      Pa.ext2("/home/a").should == nil
    end

    it "with complex" do
      Pa.ext2("/home/a.b.c.txt").should == "txt"
    end
  end

  describe ".absolute2" do
    it "returns absolute_path" do
      Pa.absolute2(".").should == File.absolute_path(".")
    end
  end

  describe ".expand2" do
    it "expand_path" do
      Pa.expand2("~").should == File.expand_path("~") 
    end
  end

	describe ".shorten2" do
		it "short /home/usr/file into ~/file" do
			ENV["HOME"] = "/home/foo"
			Pa.shorten2("/home/foo/file").should == "~/file"
		end

		it "not short /home/other-user/file" do
			ENV["HOME"] = "/home/foo"
			Pa.shorten2("/home/bar/file").should == "/home/bar/file"
		end
	end

  describe ".real2" do
    Pa.real2(".").should == File.realpath(".")
  end

	describe ".parent2" do
		before :each do
			@path = "/home/foo/a.txt"
		end

		it "return parent path" do
			Pa.parent2(@path).should == "/home/foo"
		end

		it "return parent upto 2 level path" do
			Pa.parent2(@path, 2).should == "/home"
		end
	end

  describe "class DELEGATE_METHODS" do
    it "works" do
      Pa.should_receive(:pwd2).with(1,2)

      Pa.pwd(1,2)
    end
  end
end
