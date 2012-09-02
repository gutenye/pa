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
      Dir.chdir("#{$spec_dir}/data/tmp")

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

  describe ".expand2" do
    it do
      Pa.expand2("~", ".").should == File.expand_path("~", ".") 
    end
  end

  describe ".real2" do
    it do
      Pa.real2(".", ".").should == File.realpath(".", ".")
    end
  end

  describe ".relative_to?" do
    it do
      expect(Pa.relative_to?("/home/foo", "/home")).to be_true
      expect(Pa.relative_to?("/home1/foo", "/home")).to be_false
    end
  end

	describe ".relative_to2" do
		it do
      expect(Pa.relative_to2("/home/foo", "/home")).to eq("foo")
      expect(Pa.relative_to2("/home/foo", "/home/foo")).to eq(".")
      expect(Pa.relative_to2("/home/foo", "/bin")).to eq("/home/foo")

      expect(Pa.relative_to2("/home/foo", "/home/foo/")).to eq(".")
      expect(Pa.relative_to2("/home/foo/", "/home/foo")).to eq(".")

      expect(Pa.relative_to2("/home1/foo", "/home")).to eq("/home1/foo")
		end
	end

  describe ".has_ext?" do
    it do
      expect(Pa.has_ext?("foo.txt", ".txt")).to be_true
      expect(Pa.has_ext?("foo", ".txt")).to be_false
      expect(Pa.has_ext?("foo.1txt", ".txt")).to be_false
    end
  end

  describe ".delete_ext2" do
    it do
      expect(Pa.delete_ext2("foo.txt", ".txt")).to eq("foo")
      expect(Pa.delete_ext2("foo", ".txt")).to eq("foo")
      expect(Pa.delete_ext2("foo.epub", ".txt")).to eq("foo.epub")
    end
  end

  describe ".add_ext2" do
    it do
      expect(Pa.add_ext2("foo", ".txt")).to eq("foo.txt")
      expect(Pa.add_ext2("foo.txt", ".txt")).to eq("foo.txt")
      expect(Pa.add_ext2("foo.epub", ".txt")).to eq("foo.epub.txt")
    end
  end

	describe ".shorten2" do
    it do
      Pa.stub(:home2) { "/home"}
			expect(Pa.shorten2("/home/file")).to eq("~/file")
			expect(Pa.shorten2("/home1/file")).to eq("/home1/file")

      Pa.stub(:home2) { "" }
			expect(Pa.shorten2("/home/file")).to eq("/home/file")
    end
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

  describe "DELEGATE_CLASS_METHODS" do
    it do
      Pa.should_receive(:pwd2).with(1,2)

      Pa.pwd(1,2)
    end
  end

  describe "DELEGATE_METHODS2" do
    it do
      Pa.should_receive(:parent2).with("foo", 1, 2)

      Pa.new("foo").parent2(1, 2)
    end
  end

  describe "DELEGATE_METHODS" do
    it do
      p = Pa.new("foo")

      p.should_receive(:parent2).with(1,2)
      ret = p.parent(1,2)
      ret.should be_an_instance_of(Pa)
    end
  end
end
