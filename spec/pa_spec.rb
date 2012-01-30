require "spec_helper"

class Pa
  class <<self
    public :_wrap, :build_path2
  end
end

describe Pa do
  it "._wrap" do
    Pa._wrap("foo").should == Pa("foo")
    Pa._wrap(["guten", "tag"]).should == [Pa("guten"), Pa("tag")]
  end

  describe ".build_path2" do
    it "works" do
      Pa.build_path2(path: "foo/bar.avi").should == "foo/bar.avi"
      Pa.build_path2(dir: "foo", name: "bar", ext: "avi").should == "foo/bar.avi"
    end

    it "complex examples" do
      Pa.build_path2(dir: "foo").should == "foo"
      Pa.build_path2(fname: "bar.avi").should == "bar.avi"
      Pa.build_path2(base: "bar.avi").should == "bar.avi"
      Pa.build_path2(name: "bar").should == "bar"
      Pa.build_path2(fext: ".avi").should == ".avi"
      Pa.build_path2(ext: "avi").should == ".avi"
      Pa.build_path2(dir: "", fname: "bar.avi").should == "bar.avi"
    end

    it "percedure" do
      Pa.build_path2(path: "foo", fname: "bar").should == "foo"
      Pa.build_path2(fname: "foo", name: "bar").should == "foo"
      Pa.build_path2(fname: "foo", ext: "bar").should == "foo" 
      Pa.build_path2(fname: "foo", fext: ".bar").should == "foo" 
      Pa.build_path2(fext: "foo", ext: "bar").should == "foo" 
    end
  end

  describe ".get" do
    it "get path from a path object" do
      path = Object.new
      def path.path
        "hello"
      end
      Pa.get(path).should == "hello"
    end

    it "get path from a string" do
      Pa.get("foo").should == "foo"
    end

    it "get nil from nil" do
      Pa.get(nil).should == nil
    end

    it "otherwise raise ArgumentError" do
      lambda { Pa.get([]) }.should raise_error(ArgumentError)
    end
  end

  describe "split2" do
    it "split a path into two part: dirname and basename" do
      Pa.split2("/home/b/a.txt").should == ["/home/b", "a.txt"]
    end

    it "with :all options: split all parts" do
      Pa.split2("/home/b/a.txt", :all => true).should == ["/", "home", "b", "a.txt"]
    end
  end

  describe "split" do
    it "is a special case" do
      Pa.split("/home/b/a.txt").should == [Pa("/home/b"), "a.txt"]
    end
  end

  describe ".join2" do
    it "join a path" do
      Pa.join2("/a", "b").should == "/a/b"
    end

    it "skip nil values" do
      Pa.join2("/a", "b", nil).should == "/a/b"
    end

    it "skip empty values" do
      Pa.join2("/a", "b", "").should == "/a/b"
    end
  end

  describe ".build2" do
    it "works" do
      Pa.build2("/home/guten.avi"){ |p| "#{p.dir}/foo.#{p.ext}" }.should == "/home/foo.avi"
      Pa.build2(dir: "/home", name: "guten", ext: "avi").should == "/home/guten.avi"
      Pa.build2(path: "/home/guten.avi"){ |p| "#{p.dir}/foo.#{p.ext}" }.should == "/home/foo.avi"
    end
  end

  describe "class DELEGATE_METHODS" do
    it "works" do
      Pa.stub(:build2){|arg| arg }

      Pa.build("foo").should == Pa("foo")
    end
  end

  describe "#initilaize" do
    it "support ~/foo path" do
      Pa.new("~/foo").should == Pa("#{ENV['HOME']}/foo")
    end
  end

  it "#absolute2" do
    Pa.new("foo.avi").absolute2.should == File.join(File.absolute_path("."), "foo.avi")
  end

  it "#dir2" do
    Pa.new("foo.avi").dir2.should == "."
  end

  it "#dir_strict2" do
    Pa.new("foo.avi").dir_strict2.should == ""
    Pa.new("./foo.avi").dir_strict2.should == "."
    Pa.new("../foo.avi").dir_strict2.should == ".."
    Pa.new("/foo.avi").dir_strict2.should == "/"
  end

  it "#base2" do
    Pa.new("foo.avi").base2.should == "foo.avi"
  end

  it "#name2" do
    Pa.new("foo.avi").name2.should == "foo"
  end

  it "#ext2" do
    Pa.new("foo.avi").ext2.should == "avi"
    Pa.new("foo").ext2.should == ""
  end

  it "#fext2" do
    Pa.new("foo.avi").fext2.should == ".avi"
    Pa.new("foo").ext2.should == ""
  end

  it "#inspect" do
    Pa.new("/foo/bar.avi").inspect.should =~ /path|absolute/
  end

  it "#to_s" do
    Pa.new("bar.avi").to_s.should == "bar.avi"
  end

  it "#replace" do
    a = Pa.new("/home/guten")
    a.replace "/bar/foo.avi"

    a.path.should == "/bar/foo.avi"
    a.absolute2.should == "/bar/foo.avi"
    a.dir2.should == "/bar"
    a.fname2.should == "foo.avi"
    a.base2.should == "foo.avi"
    a.name2.should == "foo"
    a.ext2.should == "avi"
    a.fext2.should == ".avi"
  end

	describe "#<=>" do
		it "runs ok" do
			(Pa("/home/b") <=> Pa("/home/a")).should == 1
		end
	end

	describe "#+" do
		it "runs ok" do
			(Pa("/home")+"~").should == Pa("/home~")
		end
	end

	describe "#sub2" do
		it "runs ok" do
			Pa("/home/foo").sub2(/o/,"").should == "/hme/foo"
		end
	end

	describe "#sub!" do
		it "runs ok" do
			pa = Pa("/home/foo")
			pa.sub!(/o/,"")
			pa.should == Pa("/hme/foo")
		end
	end

	describe "#gsub2" do
		it "runs ok" do
			Pa("/home/foo").gsub2(/o/,"").should == "/hme/f"
		end
	end

	describe "#gsub!" do
		it "runs ok" do
			pa = Pa("/home/foo")
			pa.gsub!(/o/,"")
			pa.should == Pa("/hme/f")
		end
	end

	describe "#match" do
		it "runs ok" do
			Pa("/home/foo").match(/foo/)[0].should == "foo"
		end
	end

	describe "#start_with?" do
		it "runs ok" do
			Pa("/home/foo").start_with?("/home").should be_true
		end
	end

	describe "#end_with?" do
		it "runs ok" do
			Pa("/home/foo").end_with?("foo").should be_true
		end
	end

	describe "#=~" do
		it "runs ok" do
			(Pa("/home/foo") =~ /foo/).should be_true
		end
	end

  describe "#build2" do
    it "works" do
      Pa.new("/home/guten.avi").build2(path: "/foo/bar.avi").should == "/foo/bar.avi"
      Pa.new("/home/guten.avi").build2(dir: "foo").should == "foo/guten.avi"
      Pa.new("/home/guten.avi").build2(fname: "bar").should == "/home/bar"
      Pa.new("/home/guten.avi").build2(base: "bar").should == "/home/bar"
      Pa.new("/home/guten.avi").build2(name: "bar").should == "/home/bar.avi"
      Pa.new("/home/guten.avi").build2(ext: "ogg").should == "/home/guten.ogg"
      Pa.new("/home/guten.avi").build2(fext: ".ogg").should == "/home/guten.ogg"
      Pa.new("/home/guten.avi").build2(dir: "foo", name: "bar", ext: "ogg").should == "foo/bar.ogg"
    end

    it "percedure" do
      Pa.new("/home/guten.avi").build2(path: "foo", fname: "bar").should == "foo"
      Pa.new("/home/guten.avi").build2(fname: "foo", name: "bar").should == "/home/foo"
      Pa.new("/home/guten.avi").build2(fname: "foo", ext: "ogg").should == "/home/foo"
      Pa.new("/home/guten.avi").build2(fname: "foo", fext: ".ogg").should == "/home/foo"
      Pa.new("/home/guten.avi").build2(fext: ".ogg", ext: "mp3").should == "/home/guten.ogg"
    end
  end

  describe "instance DELEGATE_METHODS2" do
    it "works" do
      Pa.stub(:join2) { "foo" }
      Pa.new("foo").join2.should == "foo"
    end
  end

  describe "instance DELEGATE_METHODS" do
    it "works" do
      Pa.stub(:build2) { "foo" }

      Pa.new("foo").build.should == Pa("foo")
    end
  end

end
