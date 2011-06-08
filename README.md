Pa, a path libraray for Ruby
========================

**Homepage**: [https://github.com/GutenLinux/pa](https://github.com/GutenLinux/pa) <br/>
**Author**:	Guten <br/>
**License**: MIT-LICENSE <br/>
**Documentation**: [http://rubydoc.info/gems/pa/frames](http://rubydoc.info/gems/pa/frames) <br/>
**Issue Tracker**: [https://github.com/GutenLinux/pa/issues](https://github.com/GutenLinux/pa/issues) <br/>

Overview
--------

An Introduction to Pa 
---------------------

	require "tagen/core"
	pa = Pa('/home/foo')
	pa.exists? #=> false
	pa.dir #=> '/home'
	pa.base #=> 'foo'
	pa.join('a.ogg') #=> '/home/a.ogg'
	pa.join(a.ogg).exists? #=> true.

	Pa.exists?('/home/foo') # alternate way

which rspec

	Pa('/home/foo').should be_exists

more see API doc

Usage
-----


Contributing
-------------

* join the project.
* report bugs/featues to issue tracker.
* fork it and pull a request.
* improve documentation.
* feel free to post any ideas. 

Install
----------

	gem install pa

Resources
---------

	some related resources to help each other.

Copyright
---------
Copyright &copy; 2011 by Guten. this library released under MIT-LICENSE, See {file:LICENSE} for futher details.
