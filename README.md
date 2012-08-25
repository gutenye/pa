# Pa, a path libraray for Ruby [![Build Status](https://secure.travis-ci.org/GutenYe/pa.png)](http://travis-ci.org/GutenYe/pa)

|                |                                      |
|----------------|--------------------------------------|
| Homepage:      |  https://github.com/GutenYe/pa       |
| Author:	       | Guten                                |
| License:       | MIT-LICENSE                          |
| Documentation: | http://rubydoc.info/gems/pa/frames   |
| Issue Tracker: | https://github.com/GutenYe/pa/issues |
| Platforms:     | Ruby 1.9.3, JRuby, Rubinius          |

Usage
-----

	require "pa"
	pa = Pa('/home/foo')
	pa.exists? #=> false
	pa.dir #=> '/home'
	pa.base #=> 'foo'
	pa.join('a.ogg') #=> '/home/a.ogg'
	pa.join(a.ogg).exists? #=> true.

	Pa.exists?('/home/foo') # alternate way

used with rspec

	Pa('/home/foo').should be_exists

more see API doc

Install
----------

	gem install pa

Contributing
-------------

* Feel free to join the project and make contributions (by submitting a pull request)
* Submit any bugs/features/ideas to github issue tracker
* Coding Style Guide: https://gist.github.com/1105334

Contributors
------------

* [contributors](https://github.com/GutenYe/pa/contributors)

Copyright
---------

(the MIT License)

Copyright (c) 2011-2012 Guten

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
