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


## Emulator

At the moment are managed the below emulators. First two are commercial which must be purchased and installed on the machine (both have x days free trial). The last is free and open source.

* [Passport web to host by Rocket Software](http://www.rocketsoftware.com/resource/rocket-passport-web-host-overview)
* [Personal communication by IBM](http://www-03.ibm.com/software/products/en/pcomm)
* [x3270 maintained by Paul Mates](http://x3270.bgp.nu/) (only on ruby 1.9+)


## Configuration

In the config folder there are three files:

   * config.rb
   * settings.yml
   * private.yml

### Emulator configuration

config.rb can be used for the configuration of the gem and the emulator

Example to configure Passport web to host:

```ruby
ButlerMainframe.configure do |config|
  config.host_gateway   = :passport
  config.browser_path   = 'c:/Program Files (x86)/Internet Explorer/iexplore.exe'
  config.session_path   = 'https://localhost/zephyr/Ecomes.zwh?sessionprofile=3270dsp/Sessions/host3270'
  config.session_tag    = 1
  config.timeout        = 3000
end
```

Example to configure Personal communication:

```ruby
ButlerMainframe.configure do |config|
  config.host_gateway   = :pcomm
  config.session_path   = '"C:/Program Files (x86)/IBM/Personal Communications/pcsws.exe" "C:/Users/Marco/AppData/Roaming/IBM/Personal Communications/host3270.ws"'
  config.session_tag    = 'A'
  config.timeout        = 3000
end
```

Example to configure X3270:

```ruby
ButlerMainframe.configure do |config|
  config.host_gateway   = :x3270
  config.session_path   = '"C:/Program Files (x86)/wc3270/ws3270.exe" 127.0.0.1 -model 2 --'
  config.timeout        = 5 # In seconds
end
```

### Configure the navigation

settings.yml and private.yml for the variables necessary to use the emulator like user, password, cics selection and everything else. Put sensible data in the second one and remember to not share it. Both have one section for every environment in rails style.

    foo: add every variable you need and use it with => ButlerMainframe::Settings.foo
        bar: sub variable are accessible with hash => ButlerMainframe::Settings.foo[:bar]


## How to use

In irb:

    C:\Ruby>irb
    irb(main):001:0> require 'butler-mainframe'
    => true

You can start the emulator 3270 manually, the butler will lean on that and will let it open at the end.
In this example, I dont start the session and immediately create a new instance:

    irb(main):002:0> host = ButlerMainframe::Host.new
    Session not found, starting new...
    Starting session with process id 8560, wait please...
    ** Connection established with host3270 **
    => #<ButlerMainframe::Host:0x29f3358 @debug=true, @wait=0.01, @wait_debug=2, @session=1, @close_session=:evaluate, @pid=8560, @action=#<WIN32OLE:0x29ebe10>>

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
# With the hook you can use a regular expression to search a label on the y axis (2 rows up and down)
# It is usefull when the y position could change (atm it does not use x axis)
host.write 'ruby on rails', :y => 6, :x => 15, hook: 'SYSTEM='

# write a text erasing the field text currently on the screen. This executes a erase_eof command before writing.
host.write 'ruby on rails', :y => 6, :x => 15, hook: 'SYSTEM=', erase_before_writing: true
# If you have to do it permanently, you can set it when you instantiate the object: host = ButlerMainframe::Host.new(erase_before_writing: true)
```

### Navigate

The aim is to speed up browsing through static screens.
The butler detects the current screen and It moves towards the target.
For example, if the current screen is the login_session and you want to go to the next, Butler log in for you.

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

This gem can be use on rails project.
Add in your gemfile

    gem 'butler-mainframe'

then

    bundle install

run generator to copy configuration files passing your emulator as parameter (default x3270)

    rails g butler:install --emulator=pcomm

My advice is to have a model for every function.
In this simple example i have to insert an invoice number on a cics map so i create the invoice model:

    rails generate scaffold invoice number:integer

You may create a polimorphic model to save mainframe screen:

    rails generate migration CreateScreens hook_id:integer 'hook_type:string{30}' 'screen_type:integer{1}' video:text 'message:string{160}' 'cursor_x:integer{1}' 'cursor_y:integer{1}'

Create something like this:

```ruby
Class Invoice
    has_many :screens, :as => :hook, :dependent => :destroy

    # ... your rails code: validations, scopes etc.

    # Your main function method that perform the action on the mainframe
    def host3270
        @host = ButlerMainframe::Host.new

        # Move to your starting position
        # They often are static screens so it's easier to use navigate method
        @host.navigate :my_starting_position

        # Always check whether we are positioned on the screen that we expect
        raise 'Screen not expected' unless @host.my_function_start_screen?

        # We develop the function.
        # In this simple case we put a number in a map CICS at row 10 and column 5
        # as option we also choose to erase any previous value in the field
        @host.write self.number, y: 10, x: 5, erase_before_writing: true

        # Press enter because the example mainframe program expects it as confirmation
        @host.do_enter

        # Read the confirmation message otherwise raise an exception
        raise 'Message not expected' unless /SUCCESSFUL/ === @host.catch_message

        # At the end close the session
        @host.close_session
    rescue
        # Save the screen as error to show to your mainframe users
        @host.screenshot :error
        # Manage the invoice status etc.
    end
end
```

If massive uses or one shot depends on your needs and according to these must be optimized the function.

The uses are many and only limited by your imagination! :rocket:

Experiment and you'll find the solution right for you

## Test

### Test models with rails

Add the butler test helper in yours rails config/application.rb before create the resource.
In this way will be added for you the test cases for that model.
Available only for the test unit framework.

```ruby
config.generators do |g|
  ...
  g.test_framework  :test_unit
  g.helper          :butler_mainframe_test
end
```

For example if you created the invoice resource:

With rails 4:

    rake test test\models\butler_mainframe_invoice_test.rb

Rails 3 is not tested yet:

    ruby -I test unit butler_mainframe_invoice_test.rb

You should get something like this:

    ** Connection established with PComm A **
    ...
    Session closed because started by this process with id 1234

    Finished in 13.044988s, 0.1533 runs/s, 0.3066 assertions/s.

    2 runs, 4 assertions, 0 failures, 0 errors, 0 skips

### Test with rake

Simple embedded tests

    bundle install
    bundle exec rake butler:mainframe:test

For more informations:

    bundle exec rake -T

These tests consist in iterations of a simple navigation sequence.
Each iteration uses different latency times, we start from high and therefore simple for the emulator to the default very low.
It is not so easy make more complex sequence to share because mainframe screens are strongly diversified but everyone can add their own and iterate as many times as deemed appropriate.


## Production environment

Which emulator choose? Well, it depends on the platform on which the application will run.

I'll try to comment supported emulators based on my experience of about 11 years in the production environment:

1. **Passport Web to Host**: on Windows 2008 R2 is stable but it can run only if scheduler user is logged in, for a production environment is a big constraint. The newer version on windows 2012 (old 2008 version cannot be installed on windows 2012 server) is even worse because there are problems of stability causing crash after long use. We are divesting.

2. **IBM Personal communication**: it happened that the session got stuck even if it was extremely rare event and i could not never attribute the blame to it. I must also mention the fact that two different processes creates only troubles. High price but at the moment seems to be the best choice.

3. **x3270**: support is improving, it's free and open source. In the future may become the best choice.

## More informations about supported emulators

I hope this can help to support my work or yours if you need something different

### Passport web to host

Documentation can be found [here](http://www.zephyrcorp.com/legacy-integration/Documentation/passport_host_integration_objects.htm) Rocket use old Zephyr documentation, unfortunately it's obsolete :disappointed:

```ruby
require 'win32ole'
passport = WIN32OLE.new("PASSPORT.System")
```

passport.ole_methods:

    # QueryInterface      # AddRef          # Release         # GetTypeInfoCount
    # GetTypeInfo         # GetIDsOfNames   # Invoke          # ActiveSession
    # Application         # DefaultFilePath # DefaultFilePath # FullName
    # Name                # Parent          # Path            # Sessions
    # TimeoutValue        # Version         # Quit            # ViewStatus
    # GetTypeInfoCount    # GetTypeInfo     # GetIDsOfNames   # Invoke
    # TimeoutValue

passport.Sessions(1).ole_methods

    # QueryInterface      # AddRef              # Release             # GetTypeInfoCount    # Toolbars
    # GetTypeInfo         # GetIDsOfNames       # Invoke              # Application         # Visible
    # ColorScheme         # ColorScheme         # Connected           # Connected           # Activate
    # EditScheme          # EditScheme          # FileTransferHostOS  # FileTransferHostOS  # SaveAs
    # FileTransferScheme  # FileTransferScheme  # FullName            # Height
    # Height              # HotSpotScheme       # HotSpotScheme       # KeyboardLocked
    # KeyboardLocked      # KeyMap              # KeyMap              # Left
    # Name                # PageRecognitionTime # PageRecognitionTime # Parent
    # Path                # QuickPads           # Saved               # Screen
    # Top                 # Top                 # Type                # Visible
    # Width               # Width               # WindowState         # WindowState
    # Close               # NavigateTo          # ReceiveFile         # Save
    # SendFile            # FileTransferOptions # GetTypeInfoCount    # GetTypeInfo
    # GetIDsOfNames       # Invoke

passport.Sessions(1).Screen.ole_methods:

    # QueryInterface     # AddRef           # Release          # GetTypeInfoCount # GetTypeInfo
    # GetIDsOfNames      # Invoke           # Application      # Col              # Col
    # Cols               # Name             # OIA              # Parent           # Row
    # Row                # Rows             # Selection        # Updated          # Area
    # Copy               # Cut              # Delete           # GetString        # MoveRelative
    # MoveTo             # Paste            # PutString        # Search           # Select
    # SelectAll          # SendInput        # SendKeys         # WaitForCursor    # WaitForCursorMove
    # WaitForKeys        # WaitForStream    # WaitForString    # WaitHostQuiet    # CheckTimeInterval
    # CheckTimeInterval  # WaitAfterAIDKey  # WaitAfterAIDKey  # GetTypeInfoCount # GetTypeInfo
    # GetIDsOfNames      # Invoke

### Personal communication

Documentation can be found [here](http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/com.ibm.pcomm.doc/books/html/host_access08.htm) Ibm did a good work!

```ruby
require 'win32ole'
session  = WIN32OLE.new("PComm.autECLSession")
session.SetConnectionByName 'A'
space   = session.autECLPS
screen  = session.autECLOIA
```

session.ole_methods:

    # QueryInterface        # AddRef                  # Release
    # GetTypeInfoCount      # GetTypeInfo             # autECLWinMetrics
    # GetIDsOfNames         # Invoke                  # Handle
    # autECLXfer            # autECLPS                # Started
    # autECLOIA             # Name                    # Ready
    # ConnType              # CodePage
    # CommStarted           # APIEnabled
    # StartCommunication    # StopCommunication
    # SetConnectionByName   # SetConnectionByHandle
    # RegisterSessionEvent  # UnregisterSessionEvent
    # RegisterCommEvent     # UnregisterCommEvent
    # autECLPageSettings    # autECLPrinterSettings
    # GetTypeInfoCount      # GetTypeInfo
    # GetIDsOfNames         # Invoke

session.autECLPS.ole_methods (presentation space):

    # QueryInterface      # AddRef                # Release             # GetTypeInfoCount 
    # GetTypeInfo         # GetIDsOfNames         # Invoke              # autECLFieldList 
    # NumRows             # NumCols               # CursorPosRow        # CursorPosCol 
    # SetConnectionByName # SetConnectionByHandle # SetCursorPos        # GetTextRect 
    # SendKeys            # SearchText            # GetText             # WaitWhileCursor 
    # SetText             # Wait                  # StartMacro          # WaitWhileStringInRect
    # WaitForCursor       # WaitWhileString       # WaitForString       # WaitForScreen  
    # WaitForStringInRect # WaitWhileAttrib       # WaitForAttrib       # UnregisterPSEvent 
    # WaitWhileScreen     # CancelWaits           # RegisterPSEvent     # Handle 
    # RegisterKeyEvent    # UnregisterKeyEvent    # RegisterCommEvent   # CommStarted 
    # UnregisterCommEvent # SetTextRect           # Name                # StopCommunication
    # ConnType            # CodePage              # Started             # Invoke
    # APIEnabled          # Ready                 # StartCommunication   
    # GetTypeInfoCount    # GetTypeInfo           # GetIDsOfNames   

session.autECLOIA.ole_methods (screen):

    # QueryInterface       # AddRef                 # Release             # GetTypeInfoCount  # UpperShift 
    # GetTypeInfo          # GetIDsOfNames          # Invoke              # Alphanumeric      # CommErrorReminder
    # APL                  # Katakana               # Hiragana            # DBCS              # ConnType   
    # NumLock              # Numeric                # CapsLock            # InsertMode        # Ready    
    # MessageWaiting       # InputInhibited         # Name                # Handle            # Invoke  
    # CodePage             # Started                # CommStarted         # APIEnabled          
    # SetConnectionByName  # SetConnectionByHandle  # StartCommunication  # StopCommunication   
    # WaitForInputReady    # WaitForSystemAvailable # WaitForAppAvailable # WaitForTransition 
    # CancelWaits          # RegisterCommEvent      # UnregisterCommEvent # RegisterOIAEvent 
    # UnregisterOIAEvent   # GetTypeInfoCount       # GetTypeInfo         # GetIDsOfNames 

### x3270

Documentation can be found [here](http://x3270.bgp.nu/documentation-manpages.html)

__At the moment it doesn't support check on protect area__

__x3270 module works only on ruby 1.9+__

```ruby
require 'open3'
stdin, stdout, thread = Open3.popen2e('"C:/Program Files (x86)/wc3270/ws3270.exe" YOUR_HOST_IP -model 2 --')
```

Read the methods list documentation: [windows](http://x3270.bgp.nu/Windows/wc3270-script.html) or [unix](http://x3270.bgp.nu/Unix/x3270-script.html)

## Found a bug?

If you are having a problem please open an issue. You can also send an email to m.mastrodonato@gmail.com

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-feature`)
3. Commit your changes (`git commit -am 'I made extensive use of all my creativity'`)
4. Push to the branch (`git push origin my-feature`)
5. Create new Pull Request

## License

The GNU Lesser General Public License, version 3.0 (LGPL-3.0)
See LICENSE file
Custom files are yours and not under license.