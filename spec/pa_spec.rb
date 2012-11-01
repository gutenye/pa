require "spec_helper"

public_all_methods Pa

describe Pa do
  it "._wrap" do
    expect(Pa._wrap("foo")).to eq(Pa("foo"))
    expect(Pa._wrap(["guten", "tag"])).to eq([Pa("guten"), Pa("tag")])
  end

  describe ".get" do
    it "get path from a path object" do
      path = Object.new
      def path.path
        "hello"
      end
      expect(Pa.get(path)).to eq("hello")
    end

    it "get path from a string" do
      expect(Pa.get("foo")).to eq("foo")
    end

    it "get nil from nil" do
      expect(Pa.get(nil)).to eq(nil)
    end

    it "otherwise raise ArgumentError" do
      expect{ Pa.get([]) }.to raise_error(ArgumentError)
    end
  end

  describe ".absolute2" do
    it do
      expect(Pa.absolute2("a.txt")).to eq(File.join(File.absolute_path(".", "."), "a.txt")) # rbx
    end
  end

  describe ".dir2" do
    it do
      expect(Pa.dir2("/home/foo.txt")).to eq("/home")
      expect(Pa.dir2("foo.txt")).to eq(".")
    end
  end

  describe ".dir_strict2" do
    it do
      expect(Pa.dir_strict2("foo.txt")).to eq("")
      expect(Pa.dir_strict2("./foo.txt")).to eq(".")
      expect(Pa.dir_strict2("../foo.txt")).to eq("..")
      expect(Pa.dir_strict2("/foo.txt")).to eq("/")
    end
  end

  describe ".base2" do
    it do
      expect(Pa.base2("foo.txt")).to eq("foo.txt")
      expect(Pa.base2("/home/foo.txt")).to eq("foo.txt")
    end


    it "(ext: true)" do
			expect(Pa.base2("/home/foo.bar", ext: true)).to eq(["foo", "bar"])
    end
  end

  describe ".base" do
    it do
      expect(Pa.base("/home/foo.txt")).to eq(Pa("foo.txt"))
			expect(Pa.base("/home/foo.bar", ext: true)).to eq([Pa("foo"), "bar"])
    end
  end

  describe ".name2" do
    it do
      expect(Pa.name2("foo.txt")).to eq("foo")
      expect(Pa.name2("/home/foo.txt")).to eq("foo")
    end
  end

  describe ".ext2" do
    it do
      expect(Pa.ext2("foo.txt")).to eq(".txt")
      expect(Pa.ext2("foo")).to eq("")
      expect(Pa.ext2("/home/foo.txt")).to eq(".txt")
    end
  end

  describe ".fext2" do
    it do
      expect(Pa.fext2("foo.txt")).to eq("txt")
      expect(Pa.fext2("foo")).to eq("")
      expect(Pa.fext2("/home/foo.txt")).to eq("txt")
    end
  end

  describe ".head2" do
    it do
      expect(Pa.head2("/bar/foo.txt.tar")).to eq("/bar/foo.txt")
      expect(Pa.head2("/bar/foo")).to eq("/bar/foo")
    end
  end

  describe "split2" do
    it "split a path into two part: dirname and basename" do
      expect(Pa.split2("/home/b/a.txt")).to eq(["/home/b", "a.txt"])
    end

    it "with :all options: split all parts" do
      expect(Pa.split2("/home/b/a.txt", :all => true)).to eq(["/", "home", "b", "a.txt"])
    end
  end

  describe "split" do
    it "is a special case" do
      expect(Pa.split("/home/b/a.txt")).to eq([Pa("/home/b"), "a.txt"])
    end
  end

  describe ".join2" do
    it "join a path" do
      expect(Pa.join2("/a", "b")).to eq("/a/b")
    end

    it "skip nil values" do
      expect(Pa.join2("/a", "b", nil)).to eq("/a/b")
    end

    it "skip empty values" do
      expect(Pa.join2("/a", "b", "")).to eq("/a/b")
    end
  end

  describe "DELEGATE_CLASS_METHODS" do
    it do
      Pa.stub(:dir2) { "foo" }
      expect(Pa.dir).to eq(Pa("foo"))
    end
  end

  describe "#initilaize" do
    it "support ~/foo path" do
      expect(Pa.new("~/foo")).to eq(Pa("#{ENV['HOME']}/foo"))
    end
  end

  describe "DELEGATE_ATTR_METHODS2" do
    it do
      Pa.stub(:dir2) { "foo" }

      a = Pa("foo")
      expect(a.dir2).to eq("foo")
      expect(a.instance_variable_get(:@dir2)).to eq("foo")
    end
  end

  describe "DELEGATE_ATTR_METHODS" do
    it do
      a = Pa("foo")
      a.stub(:dir2) { "foo" }

      expect(a.dir).to eq(Pa("foo"))
      expect(a.instance_variable_get(:@dir)).to eq(Pa("foo"))
    end
  end

  describe "DELEGATE_METHODS2" do
    it do
      Pa.stub(:join2) { "foo" }

      expect(Pa("foo").join2).to eq("foo")
    end
  end

  describe "DELEGATE_METHODS" do
    it do
      Pa.stub(:join2) { "foo" }

      expect(Pa("foo").join).to eq(Pa("foo"))
    end
  end

  describe "DELEGATE_TO_PATH2" do
    it do
      a = Pa("foo")
      a.path.stub("sub"){ "bar" }

      expect(a.sub2).to eq("bar")
    end
  end

  describe "DELEGATE_TO_PATH" do
    it do
      a = Pa("foo")
      a.path.stub("start_with?"){ "bar" }

      expect(a.start_with?).to eq("bar")
    end
  end

  describe "#inspect" do
    it do
      expect(Pa("/foo/bar.txt").inspect).to match(/path|absolute/)
    end
  end

  describe "#to_s" do
    it do
      expect(Pa("bar.txt").to_s).to eq("bar.txt")
    end
  end

  describe "#replace" do
    it do
      a = Pa("/home/guten")
      a.replace "/bar/foo.txt"

      expect(a.path     ).to eq("/bar/foo.txt")
      expect(a.absolute2).to eq("/bar/foo.txt")
      expect(a.dir2     ).to eq("/bar")
      expect(a.base2    ).to eq("foo.txt")
      expect(a.name2    ).to eq("foo")
      expect(a.ext2     ).to eq(".txt")
      expect(a.fext2    ).to eq("txt")
    end
  end

	describe "#<=>" do
		it "runs ok" do
			expect(Pa("/home/b") <=> Pa("/home/a")).to eq(1)
		end
	end

	describe "#+" do
		it "runs ok" do
			expect(Pa("/home")+"~").to eq(Pa("/home~"))
		end
	end

	describe "#sub!" do
		it "runs ok" do
			pa = Pa("/home/foo")
			pa.sub!(/o/,"")
			expect(pa).to eq(Pa("/hme/foo"))
		end
	end

	describe "#gsub!" do
		it "runs ok" do
			pa = Pa("/home/foo")
			pa.gsub!(/o/,"")
			expect(pa).to eq(Pa("/hme/f"))
		end
	end

	describe "#=~" do
		it "runs ok" do
			expect((Pa("/home/foo") =~ /foo/)).to be_true
		end
	end

  describe "#change2" do
    before :all do
      @a = Pa("/home/a.txt")
    end

    it do
      expect(@a.change2(path: "foo")).to eq("foo")
      expect(@a.change2(dir: "foo")).to eq("foo/a.txt")
      expect(@a.change2(base: "bar")).to eq("/home/bar")
      expect(@a.change2(name: "bar")).to eq("/home/bar.txt")
      expect(@a.change2(ext: ".epub")).to eq("/home/a.epub")
    end

    it "(complex)" do
      expect(@a.change2(dir: "foo", base: "bar")).to eq("foo/bar")
      expect(@a.change2(dir: "foo", name: "bar", ext: ".epub")).to eq("foo/bar.epub")
      expect(@a.change2(dir: "foo", name: "bar")).to eq("foo/bar.txt")
      expect(@a.change2(name: "bar", ext: ".epub")).to eq("/home/bar.epub")
    end

    it "has a percudure" do
      expect(@a.change2(path: "foo", dir: "bar")).to eq("foo")
      expect(@a.change2(base: "foo", name: "bar")).to eq("/home/foo")
      expect(@a.change2(base: "foo", ext: ".ogg")).to eq("/home/foo")
    end
  end
end
