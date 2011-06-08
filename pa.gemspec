$: << "."
require "version"
require "bundler"

Gem::Specification.new do |s|
	s.name = "pa"
	s.version = Pa::VERSION::IS
	s.summary = "a good lib"
	s.description = <<-EOF
a good lib
	EOF

	s.author = "Guten"
	s.email = "ywzhaifei@Gmail.com"
	s.homepage = "http://github.com/GutenLinux/pa"
	s.rubyforge_project = "xx"

	s.files = `git ls-files`.split("\n")

	s.add_bundler_dependencies
	#s.add_dependency "x"
end
