module ButlerMainframe
  # This is the host class base that contains high level logic
  # It uses sub method that have to be defined in the specific sub class
  class HostBase

    attr_reader :action, :wait
    attr_accessor :debug

    MAX_TERMINAL_COLUMNS = 80
    MAX_TERMINAL_ROWS    = 24

    def initialize options={}
      options = {
          :session          => 1,
          :wait             => 0.01,  #wait screen in seconds
          :wait_debug       => 2,     #wait time for debug purpose
          :debug            => true,
          :browser_path     => ButlerMainframe.configuration.browser_path,
          :session_path     => ButlerMainframe.configuration.session_path,
          :close_session    => :evaluate
                              #:evaluate    if the session is found will not be closed
                              #:never       never close the session
                              #:always      the session is always closed
      }.merge(options)

      @debug            = options[:debug]
      @wait             = options[:wait]
      @wait_debug       = options[:wait_debug]
      @session          = options[:session]
      @close_session    = options[:close_session]
      @pid = nil

      create_object options
    end

    # Ends the connection and closes the session
    def close_session
      puts "Closing session with criterion \"#{@close_session}\"" if @debug
      case @close_session
        when :always
          sub_close_session
          puts "Session closed" if @debug
          wait_session 0.1
        when :evaluate
          if @session_started_by_me
            sub_close_session
            puts "Session closed cause started by this process" if @debug
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
      cmd = "<#{cmd}>"
      puts "Command: #{cmd}" if @debug
      sub_exec_command cmd
      wait_session
    end

    # It reads one line or an area on the screen according to parameters supplied
    def scan options={}
      options = {
          :y => nil, :x => nil, :len => nil,
          :y1 => nil, :x1 => nil, :y2 => nil, :x2 => nil,
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
    def write text, options={}
      options = {
          :hook                       => nil,
          :y                          => nil, #riga
          :x                          => nil, #colonna
          :check                      => true,
          :raise_error_on_check       => true,
          :sensible_data              => nil,
          :clean_first_chars          => nil
      }.merge(options)

      y=options[:y]
      x=options[:x]
      raise "Missing coordinates! y(row)=#{y} x(column)=#{x} " unless x && y
      raise "Sorry, cannot write null values" unless text

      bol_written = nil
      if options[:hook]
        (y-2..y+2).each do |y_riga|
          if /#{options[:hook]}/ === scan_row(y_riga, 1, MAX_TERMINAL_COLUMNS)
            puts "Change y from #{y} to #{y_riga} cause hook to:#{options[:hook]}" if y_riga != y && @debug
            bol_written = write_clean_text_on_map text, y_riga, x, options
            break
          end
        end
      end
      #If no control is required or was not found the label reference
      bol_written = write_clean_text_on_map(text, y, x, options) unless bol_written
      bol_written
    end

    # It returns the coordinates of the cursor
    def get_cursor_axes
      sub_get_cursor_axes
    end

    private

    # It creates the object calling subclass method
    # These are the options with default values:
    #     :session          => 1,
    #     :debug            => true,
    #     :browser_path     => ButlerMainframe::Settings.browser_path,
    #     :session_path     => ButlerMainframe::Settings.session_path,
    def create_object options={}
      sub_create_object
      unless sub_object_created?
        puts "Session not found, starting new..." if @debug

        if /^1.8/ === RUBY_VERSION
          Thread.new {system "#{options[:browser_path]} #{options[:session_path]}"}
          @pid = $?.pid if $?
        else
          #It works only on ruby 1.9+
          @pid = Process.spawn "#{options[:browser_path]}", "#{options[:session_path]}"
        end

        puts "Starting session with process id #{@pid}, wait please..." if @debug
        sleep 2
        5.times do
          puts "Wait please..." if @debug
          sub_create_object
          sub_object_created? ? break : sleep(10)
        end
        @session_started_by_me = true
      end

      if sub_object_created?
        puts "** Connection established with #{sub_name} **"
        puts "Session full name: #{sub_fullname}" if @debug == :full
      else
        raise "Connection refused. Check the session #{options[:session]} and it was on the initial screen."
      end

    rescue
      puts $!.message
      raise $!
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

    # It has an additional option to clean the line before writing a value
    def write_clean_text_on_map text, y, x, options={}
      if options[:clean_first_chars] && options[:clean_first_chars].to_i > 0
        puts "Clean #{options[:clean_first_chars]} char#{options[:clean_first_chars] == 1 ? '' : 's'} y:#{y} x:#{x}" if @debug
        bol_cleaned = write_text_on_map(" " * options[:clean_first_chars], y, x, options)
        unless bol_cleaned
          puts "EHI! Impossible to clean the area specified" if @debug
          return false
        end
      end
      puts "Clean: #{options[:sensible_data] ? ('*' * text.size) : text} y:#{y} x:#{x}" if @debug
      write_text_on_map(text, y, x, options)
    end

    # Write a text on the screen
    # It also contains the logic to control the successful writing
    def write_text_on_map(text, y, x, options={})
      options = {
          :check                      => true,
          :raise_error_on_check       => true,
          :sensible_data              => nil
      }.merge(options)
      raise "Impossible to write beyond row #{MAX_TERMINAL_ROWS}" if y > MAX_TERMINAL_ROWS
      raise "Impossible to write beyond column #{MAX_TERMINAL_COLUMNS}" if x > MAX_TERMINAL_COLUMNS
      raise "Impossible to write a null value" unless text
      sub_write_text text, y, x
      # It returns the function's result
      if options[:check]
        # It expects the string is present on the session at the specified coordinates
        if sub_wait_for_string text, y, x
          return true
        else
          if options[:raise_error_on_check]
            raise "Impossible to write #{options[:sensible_data] ? ('*' * text.size) : text} at row #{y} column #{x}"
          else
            return false
          end
        end
      else
        return true
      end
    end

    # If is called a not existing method there is the chance that an optional module may not have been added
    def method_missing method_name, *args
      raise NoMethodError, "Method #{method_name} not found! Please check you have included any optional modules"
    end

  end
end

