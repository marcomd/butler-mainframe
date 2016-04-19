require 'mainframe/customization/generic_functions'

module ButlerMainframe
  # This is the host class base that contains high level logic
  # It uses sub method that have to be defined in the specific sub class
  class HostBase
    include ButlerMainframe::GenericFunctions

    attr_reader :action, :wait
    attr_accessor :debug, :close_session

    MAX_TERMINAL_COLUMNS      = 80
    MAX_TERMINAL_ROWS         = 24
    WAIT_AFTER_START_SESSION  = 3 #SECONDS

    def initialize options={}
      options = {
          :session_tag          => ButlerMainframe.configuration.session_tag,
          :wait                 => 0.01,  # wait screen in seconds
          :wait_debug           => 2,     # wait time for debug purpose
          :debug                => false,
          :browser_path         => ButlerMainframe.configuration.browser_path,
          :session_url          => ButlerMainframe.configuration.session_url,
          :session_path         => ButlerMainframe.configuration.session_path,
          :timeout              => ButlerMainframe.configuration.timeout,
          :erase_before_writing => false, # execute an erase until end of field before write a text
          :close_session        => :evaluate
                                    #:evaluate    if the session is found will not be closed
                                    #:never       never close the session
                                    #:always      the session is always closed
      }.merge(options)

      @debug                = options[:debug]
      @wait                 = options[:wait]
      @wait_debug           = options[:wait_debug]
      @session_tag          = options[:session_tag]
      @close_session        = options[:close_session]
      @timeout              = options[:timeout]
      @erase_before_writing = options[:timeout]
      @action               = {}
      @pid                  = nil

      create_object options
    end

    # Ends the connection and closes the session
    def close_session
      # puts "[DEPRECATED] .close_session will no longer be available, please use .quit"
      quit
    end
    def quit
      puts "Closing session with criterion \"#{@close_session}\"" if @debug
      case @close_session
        when :always, :yes
          sub_close_session
          puts "Session closed" if @debug
          wait_session 0.1
        when :never, :no
          if @pid
            puts "Session forced to stay open" if @debug
          else
            puts "Session not closed because it was already existing anyway it would not been closed" if @debug
          end
        when :evaluate
          if @pid
            sub_close_session
            puts "Session closed because started by this process with id #{@pid}" if @debug
            wait_session 0.1
          else
            puts "Session not closed because it was already existing" if @debug
          end
      end
    end


    # Sleep time between operations
    def wait_session wait=nil
      sleep(wait || (@debug ? @wait_debug : @wait))
    end

    # Execute keyboard command like PF1 or PA2 or ENTER ...
    def exec_command cmd
      puts "Command: #{cmd}" if @debug
      sub_exec_command cmd
      wait_session
    end

    # It reads one line or an area on the screen according to parameters supplied
    def scan options={}
      options = {
          :y  => nil, :x  => nil, :len => nil,
          :y1 => nil, :x1 => nil, :y2  => nil, :x2 => nil,
      }.merge(options)
      if options[:len]
        scan_row options[:y], options[:x], options[:len]
      else
        scan_area options[:y1], options[:x1], options[:y2], options[:x2]
      end
    end

    # Scans and returns the text of the entire page
    def scan_page
      scan_area 1, 1, MAX_TERMINAL_ROWS, MAX_TERMINAL_COLUMNS
    end

    # Write text on screen at the coordinates
    # Based on the parameters provided it writes a line or an area
    # Options:
    #     :hook                       => nil,
    #     :y                          => nil, #row
    #     :x                          => nil, #column
    #     :check                      => true,
    #     :raise_error_on_check       => true,
    #     :sensible_data              => nil,
    #     :clean_chars_before_writing => nil, # clean x chars before writing a value
    #     :erase_before_writing       => nil  # execute an erase until end of field before write a text
    def write text, options={}
      options = show_deprecated_param(:erase_field_first, :erase_before_writing, options)       if options[:erase_field_first]
      options = show_deprecated_param(:clean_first_chars, :clean_chars_before_writing, options) if options[:clean_first_chars]
      options = {
          :hook                       => nil,
          :y                          => nil,
          :x                          => nil,
          :check                      => true,
          :raise_error_on_check       => true,
          :sensible_data              => nil,
          :clean_chars_before_writing => nil,
          :erase_before_writing       => @erase_before_writing
      }.merge(options)

      y           = options[:y]
      x           = options[:x]
      y         ||= get_cursor_axes[0]
      x         ||= get_cursor_axes[1]

      hooked_rows = 2
      raise "Missing coordinates! y(row)=#{y} x(column)=#{x} "  unless x && y
      raise "Sorry, cannot write null values at y=#{y} x=#{x}"  unless text

      bol_written = false
      if options[:hook]
        (y-hooked_rows..y+hooked_rows).each do |row_number|
          if /#{options[:hook]}/ === scan_row(row_number, 1, MAX_TERMINAL_COLUMNS)
            puts "Change y from #{y} to #{row_number} cause hook to:#{options[:hook]}" if row_number != y && @debug
            bol_written = write_text_on_map text, row_number, x, options
            break
          end
        end
      else
        #If no control is required or was not found the label reference
        bol_written = write_text_on_map(text, y, x, options) unless bol_written
      end
      bol_written
    end

    # Return the coordinates of the cursor
    def get_cursor_axes
      sub_get_cursor_axes
    end

    # Move the cursor at given coordinates
    def set_cursor_axes y, x, options={}
      sub_set_cursor_axes y, x, options
    end

    private

    # It creates the object calling subclass method
    # It depends on the emulator chosen but typically the object is present after starting the terminal session
    # These are the options with default values:
    #     :session_tag      => Fixnum, String or null depending on emulator
    #     :debug            => boolean
    def create_object options={}
      connection_attempts       = 10
      seconds_between_attempts  = 1

      # Creating session object for emulators managed by API
      # Some emulator may start session terminal and return a process id in @pid
      sub_create_object options

      if sub_object_created?
        puts "Using the terminal with process id #{@pid}" if @pid && @debug
      else
        # if the terminal is not found then we start it
        puts "Session #{@session_tag} not found, starting new..." if @debug

        # Starting executable, check configuration file
        start_terminal_session options

        # New connection attempts after starting session...
        connection_attempts.times do
          puts "Detecting session #{@session_tag}, wait please..." if @debug
          sub_create_object
          sub_object_created? ? break : sleep(seconds_between_attempts)
        end
      end

      raise "Session #{@session_tag} not started. Check the session #{options[:browser_path]} #{options[:session_path]}" unless sub_object_created?

      # Session detected and waiting it become operative
      unless sub_object_ready?
        connection_attempts.times do
          puts "Waiting for the session to be ready..." if @debug
          sub_object_ready? ? break : sleep(seconds_between_attempts)
        end
      end

      # At this stage the session must be operative otherwise raise an exception
      if sub_object_ready?
        puts "** Connection established with #{sub_name} **"
        puts "Session full name: #{sub_fullname}" if @debug == :full
      else
        raise "Connection refused. Check session #{@session_tag}#{" with process id #{@pid}" if @pid}!"
      end

    rescue
      puts $!.message
      raise $!
    end

    # Starting terminal session
    # Options:
    #     :browser_path     => browser executable path, default value ButlerMainframe::Settings.browser_path (used by web emulator)
    #     :session_url      => the session url used by browser
    #     :session_path     => terminal session executable path, default value ButlerMainframe::Settings.session_path
    def start_terminal_session options
      # Check configuration to know emulator starting type
      executable, args =  if options[:browser_path] && !options[:browser_path].empty?
                            [options[:browser_path], options[:session_url]]
                          elsif options[:session_path] && !options[:session_path].empty?
                            [options[:session_path], nil]
                          else
                            [nil, nil]
                          end
      raise "Specify an executable in the configuration file!" unless executable

      if /^1.8/ === RUBY_VERSION
        Thread.new {system "#{executable} #{args}"}
        @pid = $?.pid if $?
      else
        #It works only on ruby 1.9+
        @pid = Process.spawn *[executable, args].compact
      end

      sleep WAIT_AFTER_START_SESSION
      puts "Started session with process id #{@pid}, wait please..." if @debug
    end

    #It reads one line on the screen
    def scan_row y, x, len
      str = sub_scan_row y, x, len
      puts "Scan row y:#{y} x:#{x} lungo:#{len} = #{str}" if @debug
      str
    end

    #It reads a rectangle on the screen
    def scan_area y1, x1, y2, x2
      str = sub_scan_area y1, x1, y2, x2
      puts "Scan area y1:#{y1} x1:#{x1} y2:#{y2} x2:#{x2} = #{str}" if @debug
      str
    end

    # Write a text on the screen
    # It also contains the logic to control the successful writing
    def write_text_on_map text, y, x, options={}
      options = {
          :check                      => true,
          :raise_error_on_check       => true,
          :sensible_data              => nil,
          :clean_first_chars          => nil,
          :erase_before_writing       => nil
      }.merge(options)
      raise "Impossible to write beyond row #{MAX_TERMINAL_ROWS}"       if y > MAX_TERMINAL_ROWS
      raise "Impossible to write beyond column #{MAX_TERMINAL_COLUMNS}" if x > MAX_TERMINAL_COLUMNS
      raise "Impossible to write a null value"                          unless text

      if options[:clean_first_chars] && options[:clean_first_chars].to_i > 0
        puts "write_text_on_map: Clean #{options[:clean_first_chars]} char#{options[:clean_first_chars] == 1 ? '' : 's'} y:#{y} x:#{x}" if @debug
        bol_cleaned = sub_write_text(" " * options[:clean_first_chars], y, x, :check_protect => options[:check])
        unless bol_cleaned
          puts "write_text_on_map: EHI! Impossible to clean the area specified" if @debug
          return false
        end
      end

      if options[:erase_before_writing]
        set_cursor_axes y, x
        do_erase
      end

      sub_write_text text, y, x, :check_protect => options[:check]
      res = true
      # If check is required it verify text is on the screen at given coordinates
      # Sensible data option disable the check because it could be on hidden fields
      if options[:check] && !options[:sensible_data]
        # It expects the string is present on the session at the specified coordinates
        unless sub_wait_for_string text, y, x
          if options[:raise_error_on_check]
            raise "write_text_on_map: Impossible to write #{options[:sensible_data] ? ('*' * text.size) : text} at row #{y} column #{x}"
          else
            res = false
          end
        end
      end
      res
    end

    def show_deprecated_param old, new, params={}
      #Ruby 2+ caller_locations(1,1)[0].label
      puts "[DEPRECATION] please use param :#{new} instead of :#{old} for method #{caller[0][/`([^']*)'/, 1]}"
      # Creating new param with the value of the old param
      {new => params[old]}.merge(params)
    end
    def show_deprecated_method new
      puts "[DEPRECATION] please use #{new} method instead of #{caller[0][/`([^']*)'/, 1]}"
    end

    # If is called a not existing method there is the chance that an optional module may not have been added
    def method_missing method_name, *args
      raise NoMethodError, "Method #{method_name} not found! Please check you have included any optional modules"
    end

  end
end

