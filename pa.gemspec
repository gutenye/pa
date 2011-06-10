$: << "."
require "version"

Gem::Specification.new do |s|
	s.name = "pa"
	s.version = Pa::VERSION::IS
	s.summary = "a path library for Ruby"
	s.description = <<-EOF
a path library for Ruby
	EOF

	s.author = "Guten"
	s.email = "ywzhaifei@Gmail.com"
	s.homepage = "http://github.com/GutenLinux/pa"
	s.rubyforge_project = "xx"

	s.files = `git ls-files`.split("\n")

	s.add_dependency "tagen", "~>1.0.0"
end
