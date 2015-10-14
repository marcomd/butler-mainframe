0.1.0 [☰](https://github.com/marcomd/butler-mainframe/compare/v0.0.6...v0.1.0) October 14th, 2015
------------------------------
* Added IBM personal communication support (tested on 6.0.16), use :pcomm as host gateway in butler configuration
* Many documentation improvements with technical details and examples
* Little improvements in host base to manage ready? sub methods, a new check as well as created?
* Two new config parameters: timeout and session_tag to connect to the right session
* Write text now have an option parameter :check_protect which raise an error when on protect area
* Improved passport driver class: now it use a session screen @variable to optimize memory use
* Change include module methods to monkey patch to add ruby 1.8.7 support

0.0.6 [☰](https://github.com/marcomd/butler-mainframe/compare/v0.0.5...v0.0.6) October 12th, 2015
------------------------------
* Added a simple rake test
* Improved documentation
* Some little improvements

0.0.5 October 7th, 2015
------------------------------
* First working release