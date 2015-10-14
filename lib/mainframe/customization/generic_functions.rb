# These modules contain extensions for the Host class
module Host3270
  module GenericFunctions

    def do_enter; exec_command "ENTER" end

    def go_back; exec_command "PA2" end

    def do_confirm; exec_command "PF3" end

    def do_quit; exec_command "CLEAR" end

    def do_erase; exec_command "ERASE EOF" end

    def destination_list
      [
      :company_menu,
      :cics_selection,
      :session_login,
      :next,
      :back]
    end

    def navigate destination, options={}
      options = {
          :cics             => ButlerMainframe::Settings.cics,
          :user             => ButlerMainframe::Settings.user,
          :password         => ButlerMainframe::Settings.password,
          :raise_on_abend   => false
      }.merge(options)
      attempts_number         = 10
      transactions_after_cics = ['tra1','tra2']

      raise "Destination #{destination} not valid, please use: #{destination_list.join(', ')}" unless destination_list.include? destination
      bol_found = nil
      attempts_number.times do
        if abend?
          options[:raise_on_abend] ? raise(catch_abend) : do_quit
        elsif cics?
          case destination
            when :cics_selection,
                 :session_login       then
              write "cesf logoff", :y => 1, :x => 1
              do_enter
            when :back                then
              write "cesf logoff", :y => 1, :x => 1
              do_enter
              bol_found = true; break
            when :next                then
              write transactions_after_cics[0], :y => 1, :x => 1
              do_enter
              bol_found = true; break
            when :company_menu        then write transactions_after_cics[1], :y => 1, :x => 1
            else
              #Se siamo nel cics avviamo direttamente il life
              write transactions_after_cics[0], :y => 1, :x => 1
              do_enter
          end
        elsif cics_selection?
          case destination
            when :cics_selection      then bol_found = true; break
            when :session_login       then exec_command("PF3")
            when :next                then
              cics_selection options[:cics] if options[:cics]
              bol_found = true; break
            when :back                then
              exec_command("PF3")
              bol_found = true; break
            else
              cics_selection options[:cics] if options[:cics]
          end
        elsif session_login?
          case destination
            when :session_login,
                 :back                then bol_found = true; break
            when :next                then
              session_login options[:user], options[:password] if options[:user] && options[:password]
              bol_found = true; break
            else
              session_login options[:user], options[:password] if options[:user] && options[:password]
          end
        else
          # If we do not know where we are...
          case destination
            when :back            then
              # ...we can try to go back
              go_back
              bol_found = true; break
            when :next              then
              # ...but we dont know how to move forward
            else
              # We unlock the position with both commands to be sure that they are managed by all maps cics
              go_back; do_quit
          end
        end
        wait_session
      end

      raise "It was waiting #{destination} map instead of: #{screen_title(:rows => 2).strip}" unless bol_found
    end

    def cics?
      scan(:y1 => 1, :x1 => 1, :y2 => 22, :x2 => 80).strip.empty?
    end

    #Login to mainframe
    def session_login?
      /EMSP00/i === screen_title
    end

    def session_login user, password
      puts "Starting session login..." if @debug
      wait_session
      #inizializza_sessione
      raise "It was waiting session login map instead of: #{screen_title}" unless session_login?
      write user,      :y => 16, :x => 36
      write password,  :y => 17, :x => 36, :sensible_data => true
      do_enter
    end

    # We need a label to know when we are on the cics selection map, usually ibm use EMSP01
    def cics_selection?
      /EMSP01/i === screen_title
    end

    # On this map, we have to select the cics environment
    def cics_selection cics
      puts "Starting selezione_cics..." if @debug
      wait_session
      raise "It was waiting cics selezion map instead of: #{screen_title}, messaggio: #{catch_message}" unless cics_selection?
      write cics, :y => 23, :x => 14
      do_enter
      wait_session 1
    end


    def catch_message options={}
      options = {
        :first_row                    => 22,
        :last_row                     => 23
      }.merge(options)
      scan(:y1 => options[:first_row], :x1 => 1, :y2 => options[:last_row], :x2 => 80).gsub(/\s+/, " ").strip
    end
    def catch_abend
      scan(:y1 => 23, :x1 => 1, :y2 => 23, :x2 => 80)
    end
    def abend?
      /DFHA/i === catch_abend
    end
    def screen_title options={}
      options = {
          :rows                      => 1
      }.merge(options)
      scan(:y1 => 1, :x1 => 1, :y2 => options[:rows], :x2 => 80)
    end
  end

end