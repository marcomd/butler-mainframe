require 'win32ole'
require 'mainframe/host_base'

# This class use Rocket 3270 emulator API
# http://www.rocketsoftware.com/products/rocket-passport-web-to-host
module ButlerMainframe
  class Host < HostBase

    private

    def sub_create_object
      str_obj = 'PASSPORT.System'
      puts "#{Time.now.strftime "%H:%M:%S"} Creating object #{str_obj}..." if @debug == :full
      @action = WIN32OLE.new(str_obj)
    end

    def sub_object_created?
      puts "#{Time.now.strftime "%H:%M:%S"} Terminal successfully detected" if @debug == :full
      @action.Sessions(@session)
    end

    def sub_name
      @action.Sessions(@session).Name
    end

    def sub_fullname
      @action.Sessions(@session).FullName
    end

    #Ends the connection and closes the session
    def sub_close_session
      @action.Sessions(@session).Close
      @action.Quit
      @action = nil
    end

    #Execute keyboard command like PF1 or PA2 or ENTER ...
    def sub_exec_command cmd
      @action.Sessions(@session).Screen.SendKeys cmd
      @action.Sessions(@session).Screen.WaitHostQuiet
    end

    #It reads one line part of the screen
    def sub_scan_row y, x, len
      @action.Sessions(@session).Screen.GetString(y, x, len)
    end

    #It reads a rectangle on the screen
    def sub_scan_area y1, x1, y2, x2
      @action.Sessions(@session).Screen.Area(y1, x1, y2, x2).Value
    end

    def sub_get_cursor_axes
      [@action.Sessions(@session).Screen.Col, @action.Sessions(@session).Screen.Row]
    end

    def sub_write_text text, y, x
      @action.Sessions(@session).Screen.PutString(text, y, x)
    end

    def sub_wait_for_string text, y, x
      @action.Sessions(@session).Screen.WaitForString(text, y, x).Value == -1
    end

  end
end

