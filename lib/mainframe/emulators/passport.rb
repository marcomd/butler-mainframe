require 'win32ole'

# This class use Rocket 3270 emulator API
# http://www.zephyrcorp.com/legacy-integration/Documentation/passport_host_integration_objects.htm
module ButlerMainframe
  class Host < HostBase

    private

    # Create objects from emulator library
    def sub_create_object(options={})
      str_obj = 'PASSPORT.System'
      puts "#{Time.now.strftime "%H:%M:%S"} Creating object #{str_obj}..." if @debug == :full
      @action[:object] = WIN32OLE.new(str_obj)
      if sub_object_created?
        @space  = @action[:object].Sessions(@session_tag)
        @screen = @space.Screen
      end
    end

    # Check is session is started
    def sub_object_created?
      res = @action[:object] && @action[:object].Sessions(@session_tag)
      puts "#{Time.now.strftime "%H:%M:%S"} Terminal successfully detected" if @debug == :full && res
      res
    end

    # Check is session is operative
    def sub_object_ready?
      res = @space.Connected == -1
      puts "#{Time.now.strftime "%H:%M:%S"} Session ready" if @debug == :full && res
      res
    end

    def sub_name
      "#{@action[:object].Name} #{@space.Name}"
    end

    def sub_fullname
      "#{sub_name} #{@space.FullName}"
    end

    #Ends the connection and closes the session
    def sub_close_session
      @space.Close
      @action[:object].Quit
      @action[:object] = nil
    end

    #Execute keyboard command like PF1 or PA2 or ENTER ...
    def sub_exec_command(cmd, options={})
      # Cast cmd to_s cause it could be passed as label
      @screen.SendKeys "<#{cmd.gsub /\s/, ''}>"
      @screen.WaitHostQuiet
    end

    #It reads one line part of the screen
    def sub_scan_row(y, x, len)
      @screen.GetString(y, x, len)
    end

    #It reads a rectangle on the screen
    def sub_scan_area(y1, x1, y2, x2)
      @screen.Area(y1, x1, y2, x2).Value
    end

    # Get cursor coordinates
    def sub_get_cursor_axes
      [@screen.Col, @screen.Row]
    end

    # Move cursor to given coordinates
    def sub_set_cursor_axes(y, x, options={})
      options = {
          :wait                     => true
      }.merge(options)
      @screen.MoveTo(y, x)
      @screen.WaitForCursor(y, x) if options[:wait]
    end

    # Write text on the screen at given coordinates
    # :check_protect => true add sensitivity to protected areas
    def sub_write_text(text, y, x, options={})
      options = {
          :check_protect              => true
      }.merge(options)
      if options[:check_protect]
        # This method is sensitive to protected areas
        sub_set_cursor_axes(y, x)
        @screen.SendKeys(text)
      else
        @screen.PutString(text, y, x)
      end
    end

    # Wait text at given coordinates and wait the session is available again
    def sub_wait_for_string(text, y, x)
      @screen.WaitForString(text, y, x).Value == -1
    end

    # The keyboard can be locked for any of the following reasons:
    # - The host has not finished processing your last command.
    # - You attempted to type into a protected area of the screen.
    # - You typed too many characters into a field in Insert mode.
    def sub_keyboard_locked
      @space.KeyboardLocked < 0
    end

  end
end

