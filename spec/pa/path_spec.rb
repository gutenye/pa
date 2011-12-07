require 'spec_helper'

class T_FakePath
  def path
    "hello"
  end
end

describe Pa do
  context 'dir and dir2' do
    it '#dir => Pa' do
      Pa.dir('/home/guten').should be_an_instance_of Pa
    end

    it '#dir2 => Pa' do
      Pa.dir2('/home/guten').should be_an_instance_of String
    end
  end

	describe 'NAME_EXT_PAT' do
		it 'matchs `foo.bar`' do
			'foo.bar'.match(Pa::NAME_EXT_PAT).captures.should == %w(foo bar)
		end

		it 'matchs `foo`' do
			'foo'.match(Pa::NAME_EXT_PAT).captures.should == ['foo', nil]
		end
	end

  describe '.get' do
    it 'get path from a path object' do
      Pa.get(T_FakePath.new).should == 'hello'
    end

    it 'get path from a string' do
      Pa.get('foo').should == 'foo'
    end

    it 'get nil from nil' do
      Pa.get(nil).should == nil
    end

    it 'otherwise raise ArgumentError' do
      lambda { Pa.get([]) }.should raise_error(ArgumentError)
    end
  end

  describe '.absolute?' do
    it 'is true if path is a absolute path' do
      Pa.absolute?('/').should == true
    end

    it 'is false if path is a relative path' do
      Pa.absolute?('.').should == false
    end
  end

  describe '.dangling?' do 
    it 'works' do
      olddir=Dir.pwd
      Dir.chdir("#{$specdir}/data/tmp")

      begin
        File.open('fa', 'w'){|f| f.puts "guten" }
        File.symlink('fa', 'symlink')
        File.symlink('fb', 'dangling')

        Pa.dangling?('symlink').should be_false
        Pa.dangling?('dangling').should be_true
      ensure
        FileUtils.rm_r Dir.glob("*")
        Dir.chdir(olddir)
      end
    end
  end

  describe '.pwd2' do
    olddir = Dir.getwd
    Dir.chdir('/tmp')
    begin
      Pa.pwd2.should == '/tmp'
    ensure
      Dir.chdir(olddir)
    end
  end

  describe '.dir2' do
    it "get a path's directory name" do
      Pa.dir2('/home/guten').should == '/home'
    end
  end

	describe '.base2' do
		it 'get name, ext with :ext => true' do
			Pa.base2('/home/foo.bar', ext: true).should == ['foo', 'bar']
		end
	end

  describe '.ext2' do
    it "get a path's extension" do
      Pa.ext2('/home/a.txt').should == 'txt'
    end

    it 'return nil when don extension' do
      Pa.ext2('/home/a').should == nil
    end

    it 'with complex' do
      Pa.ext2('/home/a.b.c.txt').should == 'txt'
    end
  end

  describe '.absolute2' do
    it 'returns absolute_path' do
      Pa.absolute2('.').should == File.absolute_path('.')
    end
  end

  describe '.expand2' do
    it 'expand_path' do
      Pa.expand2('~').should == File.expand_path('~') 
    end
  end

	describe '.shorten2' do
		it 'short /home/usr/file into ~/file' do
			ENV['HOME'] = '/home/foo'
			Pa.shorten2('/home/foo/file').should == '~/file'
		end

		it 'not short /home/other-user/file' do
			ENV['HOME'] = '/home/foo'
			Pa.shorten2('/home/bar/file').should == '/home/bar/file'
		end
	end

  describe '.real2' do
    Pa.real2('.').should == File.realpath('.')
  end

	describe '.parent2' do
		before :each do
			@path = '/home/foo/a.txt'
		end

		it 'return parent path' do
			Pa.parent2(@path).should == '/home/foo'
		end

		it 'return parent upto 2 level path' do
			Pa.parent2(@path, 2).should == '/home'
		end
	end

  describe 'split2' do
    it 'split a path into two part: dirname and basename' do
      Pa.split2('/home/b/a.txt').should == ['/home/b', 'a.txt']
    end

    it 'with :all options: split all parts' do
      Pa.split2('/home/b/a.txt', :all => true).should == ['/', 'home', 'b', 'a.txt']
    end
  end

  describe 'split' do
    it 'is a special case' do
      Pa.split('/home/b/a.txt').should == [Pa('/home/b'), 'a.txt']
    end
  end

  describe '.join2' do
    it 'join a path' do
      Pa.join2('/a', 'b').should == '/a/b'
    end

    it 'skip nil values' do
      Pa.join2('/a', 'b', nil).should == '/a/b'
    end

    it 'skip empty values' do
      Pa.join2('/a', 'b', '').should == '/a/b'
    end
  end

	describe '#==' do
		it 'runs ok' do
			(Pa('/home') == Pa('/home')).should be_true
		end
	end

	describe '#+' do
		it 'runs ok' do
			(Pa('/home')+'~').should == Pa('/home~')
		end
	end

	describe '#sub2' do
		it 'runs ok' do
			Pa('/home/foo').sub2(/o/,'').should == '/hme/foo'
		end
	end

	describe '#sub!' do
		it 'runs ok' do
			pa = Pa('/home/foo')
			pa.sub!(/o/,'')
			pa.should == Pa('/hme/foo')
		end
	end

	describe '#gsub2' do
		it 'runs ok' do
			Pa('/home/foo').gsub2(/o/,'').should == '/hme/f'
		end
	end

	describe '#gsub!' do
		it 'runs ok' do
			pa = Pa('/home/foo')
			pa.gsub!(/o/,'')
			pa.should == Pa('/hme/f')
		end
	end

	describe '#match' do
		it 'runs ok' do
			Pa('/home/foo').match(/foo/)[0].should == 'foo'
		end
	end

	describe '#start_with?' do
		it 'runs ok' do
			Pa('/home/foo').start_with?('/home').should be_true
		end
	end

	describe '#end_with?' do
		it 'runs ok' do
			Pa('/home/foo').end_with?('foo').should be_true
		end
	end

	describe '#=~' do
		it 'runs ok' do
			(Pa('/home/foo') =~ /foo/).should be_true
		end
	end
end
