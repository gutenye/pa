$: << File.expand_path("../lib", __FILE__)
require "pa/version"

Gem::Specification.new do |s|
	s.name = "pa"
	s.version = Pa::VERSION
	s.summary = "a path library for Ruby"
	s.description = <<-EOF
a path library for Ruby
	EOF

	s.author = "Guten"
	s.email = "ywzhaifei@Gmail.com"
	s.homepage = "http://github.com/GutenYe/pa"
	s.rubyforge_project = "xx"

	s.files = `git ls-files`.split("\n")
end
