require 'win32ole'
require 'mainframe/host_base'

# This class use IBM personal communication
# http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/welcome.html
# http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/com.ibm.pcomm.doc/books/html/host_access08.htm
# http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/com.ibm.pcomm.doc/books/html/admin_guide10.htm?lang=en
module ButlerMainframe
  class Host < HostBase

    private

    # Create objects from emulator library
    def sub_create_object options={}
      str_obj = 'PComm.autECLSession'
      puts "#{Time.now.strftime "%H:%M:%S"} Creating object #{str_obj}..." if @debug == :full
      @action[:ole] = WIN32OLE.new(str_obj)
      @action[:ole].SetConnectionByName @session_tag
      @space  = @action[:ole].autECLPS
      @screen = @action[:ole].autECLOIA
    end

    # Check is session is started
    def sub_object_created?
      res = @action[:ole] && @action[:ole].CommStarted
      puts "#{Time.now.strftime "%H:%M:%S"} Terminal successfully detected" if @debug == :full && res
      res
    end

    # Check is session is operative
    def sub_object_ready?
      res = @action[:ole].Ready
      puts "#{Time.now.strftime "%H:%M:%S"} Session ready" if @debug == :full && res
      res
    end

    def sub_name
      "PComm #{@action[:ole].Name}"
    end

    def sub_fullname
      "#{sub_name} #{@action[:ole].ConnType}"
    end

    #Ends the connection and closes the session
    def sub_close_session
      @action[:ole].StopCommunication
      @action[:ole] = nil
      # See http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/com.ibm.pcomm.doc/books/html/admin_guide10.htm?lang=en
      Process.spawn "PCOMSTOP /S=#{@session_tag} /q" if @pid
      # Process.kill 9, @pid #Another way is to kill the process but the session start 2nd process pcscm.exe
    end

    #Execute keyboard command like PF1 or PA2 or ENTER ...
    def sub_exec_command cmd, options={}
      # Cast cmd to_s cause it could be passed as label
      @space.SendKeys "[#{cmd}]"
      @screen.WaitForAppAvailable @timeout
      @screen.WaitForInputReady @timeout
    end

    #It reads one line part of the screen
    def sub_scan_row y, x, len
      @space.GetText(y, x, len)
    end

    #It reads a rectangle on the screen
    def sub_scan_area y1, x1, y2, x2
      @space.GetTextRect(y1, x1, y2, x2)
    end

    # Get cursor coordinates
    def sub_get_cursor_axes
      [@space.CursorPosCol, @space.CursorPosRow]
    end

    # Move cursor to given coordinates
    def sub_set_cursor_axes y, x, options={}
      options = {
          :wait                     => true
      }.merge(options)
      @space.SetCursorPos y, x
      @space.WaitForCursor(y, x, @timeout) if options[:wait]
    end

    # Write text on the screen at given coordinates
    # :check_protect => true add sensitivity to protected areas
    def sub_write_text text, y, x, options={}
      options = {
          :check_protect              => true
      }.merge(options)
      if options[:check_protect]
        # This method is sensitive to protected areas
        @space.SendKeys(text, y, x)
      else
        @space.SetText(text, y, x)
      end
    end

    # Wait text at given coordinates and wait the session is available again
    def sub_wait_for_string text, y, x
      @space.WaitForString text, y, x, @timeout
      @screen.WaitForInputReady @timeout
    end

  end
end

