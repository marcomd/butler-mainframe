require 'open3'

# This class use X3270, an interesting project open source
# http://x3270.bgp.nu/Windows/wc3270-script.html
# http://x3270.bgp.nu/Windows/ws3270-man.html
module ButlerMainframe
  class Host < HostBase

    private

    def sub_create_object(options={})
      str_obj = "#{options[:session_path]}"
      puts "#{Time.now.strftime "%H:%M:%S"} Creating object #{str_obj}..." if @debug == :full
      @action = {}
      @action[:in], @action[:out], @action[:thr] = Open3.popen2e(str_obj)
      @action[:object] = true
      sleep WAIT_AFTER_START_SESSION
      @pid = @action[:thr].pid
    end

    # Check is session is started
    def sub_object_created?
      res = @action[:in] && @action[:out] && @action[:thr]
      puts "#{Time.now.strftime "%H:%M:%S"} Terminal successfully detected" if @debug == :full && res
      res
    end

    # Check is session is operative
    def sub_object_ready?
      res = !x_cmd("Query(ConnectionState)").strip.empty?
      puts "#{Time.now.strftime "%H:%M:%S"} Session ready" if @debug == :full && res
      res
    end

    def sub_name
      "X3270 #{x_cmd "Query(Host)"}".strip
    end

    def sub_fullname
      "#{sub_name} #{x_cmd "Query(LuName)"}".strip
    end

    #Ends the connection and closes the session
    def sub_close_session
      @action[:in].close
      @action[:out].close
      @action[:object] = nil
    end

    #Execute keyboard command like PF1 or PA2 or ENTER ...
    def sub_exec_command cmd, options={}
      cmd = cmd.split.map(&:capitalize).join
      if m=/^(Pf|Pa)(\d+)$/.match(cmd)
        cmd = "#{m[1]}(#{m[2]})"
      end
      x_cmd cmd

      command_skip_wait = %w(^erase ^delete)
      x_cmd("Wait(#{@timeout}, Output)") unless /(#{command_skip_wait.join('|')})/i === cmd
    end

    #It reads one line part of the screen
    def sub_scan_row y, x, len
      x_cmd "Ascii(#{y-1},#{x-1},#{len})"
    end

    #It reads a rectangle on the screen
    def sub_scan_area y1, x1, y2, x2
      x_cmd "Ascii(#{y1-1},#{x1-1},#{y2-y1+1},#{x2-x1+1})"
    end

    # Get cursor coordinates
    def sub_get_cursor_axes
      res = x_cmd("Query(Cursor)")
      res.split.map { |c| c.to_i + 1 }
    end

    # Move cursor to given coordinates
    def sub_set_cursor_axes(y, x, options={})
      options = {
          :wait                     => true
      }.merge(options)
      x_cmd("MoveCursor(#{y-1},#{x-1})")
      if options[:wait]
        x_cmd("Wait(#{@timeout},InputField)")
        raise "Positioning the cursor at the coordinates (#{y}, #{x}) failed!" unless sub_get_cursor_axes == [y, x]
      end
    end

    # Write text on the screen at given coordinates
    # :check_protect => true add sensitivity to protected areas
    def sub_write_text(text, y, x, options={})
      options = {
          :check_protect              => true
      }.merge(options)
      sub_set_cursor_axes(y, x)
      x_cmd "String(\"#{text}\")", options
      # TODO
      # if options[:check_protect]
      # end
    end

    # Wait text at given coordinates
    def sub_wait_for_string(text, y, x)
      x_cmd "Wait(#{@timeout},InputField)"
      total_time = 0.0
      sleep_time = 0.5
      while sub_scan_row(y, x, text.size) != text do
        sleep sleep_time
        total_time = total_time + sleep_time
        # @timeout should be in milliseconds but everything is possible
        break if total_time >= @timeout
      end
      sub_scan_row(y, x, text.size) == text
    end

    # To communicate with executable
    def x_cmd(cmd, options={})
      puts "x_cmd in: #{options[:sensible_data] ? ('*' * cmd.size) : cmd}" if @debug == :full
      @action[:in].print "#{cmd}\n"
      @action[:in].flush

      str_res_ok = 'ok'
      ar_res = [str_res_ok, 'error']

      line, str_out = '', ''
      while line = @action[:out].gets.chomp do
        puts "x_cmd out: '#{line}'" if @debug == :full
        break if ar_res.include? line
        str_out << "#{line[6..-1]}" if /^data:\s/ === line
      end
      line == str_res_ok ? str_out : raise(str_out)
    end

  end
end

