# These modules contain extensions for the Host class
module ButlerMainframe
  module GenericFunctions

    # If you add your static screen you must add it in the navigation method to define how to manage it
    def destination_list
      [:company_menu,
       :cics_selection,
       :session_login,
       :next,
       :back]
    end

    # Use navigation method to move through the static screens
    # Options:
    # :cics             => ButlerMainframe::Settings.cics,
    # :user             => ButlerMainframe::Settings.user,
    # :password         => ButlerMainframe::Settings.password,
    # :raise_on_abend   => false raise an exception if an abend is occured
    def navigate destination, options={}
      options = {
          :session_user     => ButlerMainframe::Settings.session_user,
          :session_password => ButlerMainframe::Settings.session_password,
          :cics             => ButlerMainframe::Settings.cics,
          :company_menu     => ButlerMainframe::Settings.company_menu,
          :raise_on_abend   => false
      }.merge(options)
      max_attempts_number   = ButlerMainframe::Settings.max_attempts_number
      transactions_cics     = ButlerMainframe::Settings.transactions_cics

      raise "Destination #{destination} not valid, please use: #{destination_list.join(', ')}" unless destination_list.include? destination

      puts "Navigating to #{destination}" if @debug
      destination_found = nil
      attempt_number    = 0
      while !destination_found do
        attempt_number += 1

        if abend?
          puts "Navigate: abend" if @debug
          options[:raise_on_abend] ? raise(catch_abend) : do_quit
        elsif company_menu?
          puts "Navigating to #{destination} from company menu" if @debug
          case destination
            when  :cics_selection,
                  :session_login      then
              do_quit
            when  :back               then
              do_quit
              destination_found = true
            when :next                then
              company_menu options[:company_menu]
              destination_found = true
            when :company_menu        then destination_found = true
            else
              # Every other destination is forward
              company_menu options[:company_menu]
          end
        elsif cics?
          puts "Navigating to #{destination} from cics" if @debug
          case destination
            when :cics_selection,
                 :session_login       then
              execute_cics ButlerMainframe::Settings.logoff_cics
            when :back                then
              execute_cics ButlerMainframe::Settings.logoff_cics
              destination_found = true
            when :next                then
              execute_cics transactions_cics[:main_application]
              destination_found = true
            when :company_menu        then
              execute_cics transactions_cics[:company_menu]
            else
              #If we are in CICS with blank screen start the first transaction
              execute_cics transactions_cics[:main_application]
          end
        elsif cics_selection?
          puts "Navigating to #{destination} from cics selection" if @debug
          case destination
            when :cics_selection      then destination_found = true
            when :session_login       then exec_command("PF3")
            when :next                then
              cics_selection options[:cics] if options[:cics]
              destination_found = true
            when :back                then
              exec_command("PF3")
              destination_found = true
            else
              cics_selection options[:cics] if options[:cics]
          end
        elsif session_login?
          puts "Navigating to #{destination} from session login" if @debug
          case destination
            when :session_login,
                 :back                then destination_found = true
            when :next                then
              session_login options[:session_user], options[:session_password]
              destination_found = true
            else
              session_login options[:session_user], options[:session_password]
          end
        else
          puts "Navigating to #{destination} from unknown screen" if @debug
          # If we do not know where we are...
          case destination
            when  :session_login      then
              # ...to come back to the first screen we surely have to go back
              go_back
            when  :back               then
              # ...we can try to go back (not all the screen may go back in the same way)
              go_back
              destination_found = true
            when :next                then
              # ...but we dont know how to move forward
              raise "Define how to go forward in the navigation method on generic function module"
            else
              # We unlock the position with both commands to be sure that they are managed by all maps cics
              raise "Destination #{destination} not defined in the current screen"
          end
        end
        break if attempt_number > max_attempts_number
        wait_session
      end

      raise "It was waiting #{destination} map instead of: #{screen_title(:rows => 2).strip}" unless destination_found
    end

    # Check if we are the first blank cics screen
    def cics?
      scan(:y1 => 1, :x1 => 1, :y2 => 22, :x2 => 80).strip.empty?
    end

    # Check if we are on the login mainframe screen
    def session_login?
      /#{ButlerMainframe::Settings.session_login_tag}/i === screen_title
    end

    # Login to mainframe
    # param1 user(array)        [text, y, x]
    # param2 password(array)    [text, y, x]
    def session_login ar_user, ar_password
      puts "Starting session login..." if @debug
      user,     y_user,     x_user      = ar_user
      raise "Check session user configuration! #{user} #{y_user} #{x_user}" unless user && y_user && x_user
      password, y_password, x_password  = ar_password
      raise "Check session password configuration! #{password} #{y_password} #{x_password}" unless password && y_password && x_password

      wait_session
      #inizializza_sessione
      raise "It was waiting session login map instead of: #{screen_title}" unless session_login?
      write user,      :y => y_user,      :x => x_user
      write password,  :y => y_password,  :x => x_password, :sensible_data => true
      do_enter
    end

    # Check the label to know when we are on the cics selection map
    def cics_selection?
      /#{ButlerMainframe::Settings.cics_selection_tag}/i === screen_title
    end

    # On this map, we have to select the cics environment
    # param1 cics(array)        [text, y, x]
    def cics_selection ar_cics
      puts "Starting selezione_cics..." if @debug
      cics, y_cics, x_cics = ar_cics
      raise "Check cics configuration! #{cics} #{y_cics} #{x_cics}" unless cics && y_cics && x_cics

      wait_session
      raise "It was waiting cics selezion map instead of: #{screen_title}, message: #{catch_message}" unless cics_selection?
      write cics, :y => y_cics,   :x => x_cics
      do_enter
      wait_session 1
    end

    # Check the label to know when we are on the cics selection map
    def company_menu?
      /#{ButlerMainframe::Settings.company_menu_tag}/i === screen_title
    end

    # On this map, we have to select the cics environment
    # param1 cics usually is a number
    def company_menu ar_menu
      puts "Starting company menu..." if @debug
      menu, y_menu, x_menu = ar_menu
      raise "Check company menu configuration! #{menu} #{y_menu} #{x_menu}" unless menu && y_menu && x_menu

      wait_session
      raise "It was waiting company menu map instead of: #{screen_title}, message: #{catch_message}" unless company_menu?
      write menu, :y => y_menu, :x => x_menu
      do_enter
    end

    # Get the message line usually in the bottom of the screen
    # You can define which rows provide the message:
    #     :first_row                    => 22,
    #     :last_row                     => 23
    def catch_message options={}
      options = {
        :first_row                    => 22,
        :last_row                     => 23
      }.merge(options)
      scan(:y1 => options[:first_row], :x1 => 1, :y2 => options[:last_row], :x2 => 80).gsub(/\s+/, " ").strip
    end

    # Get the abend message
    def catch_abend
      scan(:y1 => 23, :x1 => 1, :y2 => 23, :x2 => 80)
    end

    # Check if there was a malfunction on the mainframe
    def abend?
      /DFHA/i === catch_abend
    end

    # Get the title usually the first row
    # You can change default option :rows to get more lines starting from the first
    def screen_title options={}
      options = {
          :rows                      => 1
      }.merge(options)
      scan(:y1 => 1, :x1 => 1, :y2 => options[:rows], :x2 => 80)
    end

    def execute_cics name
      write name, :y => 1, :x => 2
      do_enter
    end

    def do_enter;   exec_command "ENTER"      end

    def go_back;    exec_command "PA2"        end

    def do_confirm; exec_command "PF3"        end

    def do_quit;    exec_command "CLEAR"      end

    def do_erase;   exec_command "ERASE EOF"  end

  end

end