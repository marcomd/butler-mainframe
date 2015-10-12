# Butler-mainframe

[![Version     ](http://img.shields.io/gem/v/butler-mainframe.svg)                     ](https://rubygems.org/gems/butler-mainframe)
[![Quality     ](http://img.shields.io/codeclimate/github/marcomd/butler-mainframe.svg)](https://codeclimate.com/github/marcomd/butler-mainframe)

This gem provides a virtual butler which can perform your custom tasks on a 3270 emulator.
You just have to choose your emulator and configure your tasks.

## Compatibility

Developed on a windows plaftorm.


## Install

Instal the gem from rubygems

    gem install butler-mainframe

Then you have to install your favorite emulator.
At the moment is supported only [Passport web to host by rocket software](http://www.rocketsoftware.com/products/rocket-passport-web-to-host)

## How to use

In irb:

    C:\Ruby>irb
    irb(main):001:0> require 'butler-mainframe'

    Use ButlerMainframe::Host.new
    Please read the documentation on github for more information
    => true
    irb(main):002:0>

You can start the emulator 3270 manually, the butler will lean on that and will let it open at the end.
In this example, I dont start the session and immediately create a new instance:

    irb(main):002:0> host = ButlerMainframe::Host.new
    Session not found, starting new...
    Starting session with process id 8560, wait please...
    ** Connection established with host3270 **
    => #<ButlerMainframe::Host:0x29f3358 @debug=true, @wait=0.01, @wait_debug=2, @session=1, @close_session=:evaluate, @pid=8560, @action=#<WIN32OLE:0x29ebe10>, @session_started_by_me=true>

now session is ready to use:

    host.scan_page

should return what you see on your terminal

## Commands

You can do anything (disclaimer: as long as it was planned :innocent:)

### Scan
```ruby
# Scan and return all text in the terminal:
host.scan_page

# only a rectangle, in this example the first two rows:
host.scan x1: 1, y1: 1, x2: 80, y2: 2

# only a text
host.scan x: 10, y: 10, len: 10
```

### Write
```ruby
# write a text at the coordinates
host.write 'ruby on rails', :y => 6, :x => 15

# write a text using a hook
# With the hook you can use a regular expression to search a label on the y axis (3 rows up and down)
# It is usefull when the y position could change (atm it does not use x axis)
host.write 'ruby on rails', :y => 6, :x => 15, hook: 'SYSTEM='
```

### Navigate

The aim is to speed up browsing through static screens.
The butler detects the current screen and It moves towards the target.
For example, if the current screen is the login_session and you want to go to the next, to do that Butler log in
In this case it identifies the first map the session login to the mainframe and it does the login to go to the next screen.

```ruby
# Go to the login session screen
host.navigate :login_session

# Now go to the next
host.navigate :next

# To go to the next screen Butler login for you

# Go back is simple as well
host.navigate :back

# You can configure your own destination in the generic functions module
host.navigate :your_favourite_screen
```

This is possible because it is configured in the navigate method which have to be configured to fit your needs. You can find it inside lib\mainframe\customization.

My advice is to use navigate method for generic navigation and use a specific module (or rails model) for each task.

## With Rails

__In development...__
This module can be use on rails project.
Add in your gemfile

    gem 'butler-mainframe'

then

    bundle install

run generator to copy configuration files

    rails g butler:install

```ruby
Class Invoice
    # ... your code

    def host3270
        @host = ButlerMainframe::Host.new
        @host.navigate :my_starting_position

        # Always check whether we are positioned on the screen that we expect
        raise 'Screen not expected' unless self.my_function_start_screen?

        # We develop the function.
        # In this simple case we put a number in a map cics and press Enter
        @host.write self.invoice_number
        @host.do_enter

        # to read the confirmation message
        raise 'Message not expected' unless /SUCCESSFUL/ === self.catch_message

        @host.close_session
    rescue
        host.screenshot :error
        # Manage the invoice status etc.
    end
end
```

Create a polimorphic model:
rails generate screen hook_id:integer 'hook_type:string{30}' 'screen_type:integer{1}' video:text 'message:string{160}' 'cursor_x:integer{1}' 'cursor_y:integer{1}'

In the model to be related to screen we insert:
has_many :screens, :as => :hook, :dependent => :destroy


## Test with rake

Simple embedded tests

    bundle install
    bundle exec rake butler:mainframe:test

For more informations:

    bundle exec rake -T


## License

The GNU Lesser General Public License, version 3.0 (LGPL-3.0)
See LICENSE file
Custom files are yours and not under license.


## Found a bug?

If you are having a problem please submit an issue at
* m.mastrodonato@gmail.com




