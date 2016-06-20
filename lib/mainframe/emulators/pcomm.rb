require 'win32ole'

# This class use IBM personal communication
# http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/welcome.html
# http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/com.ibm.pcomm.doc/books/html/host_access08.htm
# http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/com.ibm.pcomm.doc/books/html/admin_guide10.htm?lang=en
module ButlerMainframe
  class Host < HostBase

    private

    # Create objects from emulator library
    def sub_create_object(options={})
      str_obj = 'PComm.autECLSession'
      puts "#{Time.now.strftime "%H:%M:%S"} Creating object #{str_obj}..." if @debug == :full
      @action[:object] = WIN32OLE.new(str_obj)
      @action[:object].SetConnectionByName @session_tag
      @space  = @action[:object].autECLPS
      @screen = @action[:object].autECLOIA
      if @action[:object] && @action[:object].Started && !@action[:object].CommStarted
        @action[:object].StartCommunication
        wait_session(WAIT_AFTER_START_CONNECTION)
      end
    end

    # Check is session is started
    def sub_object_created?
      res = @action[:object] && @action[:object].CommStarted
      puts "#{Time.now.strftime "%H:%M:%S"} Terminal successfully detected" if @debug == :full && res
      res
    end

    # Check is session is operative
    def sub_object_ready?
      res = @action[:object].Ready
      puts "#{Time.now.strftime "%H:%M:%S"} Session ready" if @debug == :full && res
      res
    end

    def sub_name
      "PComm #{@action[:object].Name}"
    end

    def sub_fullname
      "#{sub_name} #{@action[:object].ConnType}"
    end

    #Ends the connection and closes the session
    def sub_close_session
      #@action[:object].StopCommunication #Removed due to session stuck if it will not be closed
      @action[:object] = nil
      if @pid
        # See http://www-01.ibm.com/support/knowledgecenter/SSEQ5Y_6.0.0/com.ibm.pcomm.doc/books/html/admin_guide10.htm?lang=en
        cmd_stop = "PCOMSTOP /S=#{@session_tag} /q"
        if /^1.8/ === RUBY_VERSION
          Thread.new { system cmd_stop }
        else
          Process.spawn(cmd_stop)
        end
        # Process.kill 9, @pid #Another way is to kill the process but the session start 2nd process pcscm.exe
      end
    end

    #Execute keyboard command like PF1 or PA2 or ENTER ...
    def sub_exec_command(cmd, options={})
      command_skip_timeout = %w(^erase ^delete)
      timeout = /(#{command_skip_timeout.join('|')})/i === cmd ? @timeout_screen : @timeout
      # Cast cmd to_s cause it could be passed as label
      @space.SendKeys("[#{cmd}]")
      @screen.WaitForAppAvailable(timeout)
      @screen.WaitForInputReady(timeout)
    end

    #It reads one line part of the screen
    def sub_scan_row(y, x, len)
      @space.GetText(y, x, len)
    end

    #It reads a rectangle on the screen
    def sub_scan_area(y1, x1, y2, x2)
      @space.GetTextRect(y1, x1, y2, x2)
    end

    # Get cursor coordinates
    def sub_get_cursor_axes
      [@space.CursorPosCol, @space.CursorPosRow]
    end

    # Move cursor to given coordinates
    def sub_set_cursor_axes(y, x, options={})
      options = {
          :wait                     => true
      }.merge(options)
      @space.SetCursorPos(y, x)
      @space.WaitForCursor(y, x, @timeout) if options[:wait]
    end

    # Write text on the screen at given coordinates
    # :check_protect => true add sensitivity to protected areas
    def sub_write_text(text, y, x, options={})
      options = {
          :check_protect              => true
      }.merge(options)
      if options[:check_protect]
        # This method is sensitive to protected areas
        @space.SendKeys(text, y, x)
      else
        @space.SetText(text, y, x)
      end
      true
    end

    # Wait text at given coordinates and wait the session is available again
    def sub_wait_for_string(text, y, x)
      @space.WaitForString(text, y, x, @timeout_screen)
      @screen.WaitForInputReady(@timeout_screen)
    end

    # The keyboard can be locked for any of the following reasons:
    # - The host has not finished processing your last command.
    # - You attempted to type into a protected area of the screen.
    # - You typed too many characters into a field in Insert mode.
    def sub_keyboard_locked
      @screen.InputInhibited > 0
    end

  end
end

