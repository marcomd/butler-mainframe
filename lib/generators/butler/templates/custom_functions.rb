# These modules contain extensions for the Host class
module Host3270
  module CustomFunctions
    ### Insert here your custom methods ###

    ### Update default generic function ###
    # def do_enter; exec_command "ENTER" end
    #
    # def go_back; exec_command "PA2" end
    #
    # def do_confirm; exec_command "PF3" end
    #
    # def do_quit; exec_command "CLEAR" end
    #
    # def do_erase; exec_command "ERASE EOF" end
    #
    # # If you add your static screen you must add it in the navigation method to define how to manage it
    # def destination_list
    #   [
    #       :company_menu,
    #       :cics_selection,
    #       :session_login,
    #       :next,
    #       :back]
    # end
    #
    # # Use navigation method to move through the static screens
    # # Options:
    # # :cics             => ButlerMainframe::Settings.cics,
    # # :user             => ButlerMainframe::Settings.user,
    # # :password         => ButlerMainframe::Settings.password,
    # # :raise_on_abend   => false raise an exception if an abend is occured
    # def navigate destination, options={}
    #   options = {
    #       :cics             => ButlerMainframe::Settings.cics,
    #       :user             => ButlerMainframe::Settings.user,
    #       :password         => ButlerMainframe::Settings.password,
    #       :raise_on_abend   => false
    #   }.merge(options)
    #   attempts_number       = ButlerMainframe::Settings.navigation_iterations
    #   transactions_cics     = ButlerMainframe::Settings.transactions_cics
    #
    #   raise "Destination #{destination} not valid, please use: #{destination_list.join(', ')}" unless destination_list.include? destination
    #   bol_found = nil
    #   attempts_number.times do
    #     if abend?
    #       options[:raise_on_abend] ? raise(catch_abend) : do_quit
    #     elsif company_menu?
    #       case destination
    #         when  :cics_selection,
    #             :session_login      then
    #           do_quit
    #         when  :back               then
    #           do_quit
    #           bol_found = true; break
    #         when :next                then
    #           company_menu
    #           bol_found = true; break
    #         when :company_menu        then bol_found = true; break
    #         else
    #           # Every other destination is forward
    #           company_menu
    #       end
    #     elsif cics?
    #       case destination
    #         when :cics_selection,
    #             :session_login       then
    #           write ButlerMainframe::Settings.logoff_cics, :y => 1, :x => 1
    #           do_enter
    #         when :back                then
    #           write ButlerMainframe::Settings.logoff_cics, :y => 1, :x => 1
    #           do_enter
    #           bol_found = true; break
    #         when :next                then
    #           write transactions_cics[:main_application], :y => 1, :x => 1
    #           do_enter
    #           bol_found = true; break
    #         when :company_menu        then
    #           write transactions_cics[:company_menu], :y => 1, :x => 1
    #           do_enter
    #         else
    #           #If we are in CICS with blank screen start the first transaction
    #           write transactions_cics[:main_application], :y => 1, :x => 1
    #           do_enter
    #       end
    #     elsif cics_selection?
    #       case destination
    #         when :cics_selection      then bol_found = true; break
    #         when :session_login       then exec_command("PF3")
    #         when :next                then
    #           cics_selection options[:cics] if options[:cics]
    #           bol_found = true; break
    #         when :back                then
    #           exec_command("PF3")
    #           bol_found = true; break
    #         else
    #           cics_selection options[:cics] if options[:cics]
    #       end
    #     elsif session_login?
    #       case destination
    #         when :session_login,
    #             :back                then bol_found = true; break
    #         when :next                then
    #           session_login options[:user], options[:password] if options[:user] && options[:password]
    #           bol_found = true; break
    #         else
    #           session_login options[:user], options[:password] if options[:user] && options[:password]
    #       end
    #     else
    #       # If we do not know where we are...
    #       case destination
    #         when  :session_login    then
    #           # ...to come back to the first screen we surely have to go back
    #           go_back
    #         when  :back               then
    #           # ...we can try to go back (not all the screen may go back in the same way)
    #           go_back
    #           bol_found = true; break
    #         when :next              then
    #           # ...but we dont know how to move forward
    #           raise "Define how to go forward in the navigation method on generic function module"
    #         else
    #           # We unlock the position with both commands to be sure that they are managed by all maps cics
    #           raise "Destination #{destination} not defined in the current screen"
    #       end
    #     end
    #     wait_session
    #   end
    #
    #   raise "It was waiting #{destination} map instead of: #{screen_title(:rows => 2).strip}" unless bol_found
    # end
    #
    # # Check if we are the first blank cics screen
    # def cics?
    #   scan(:y1 => 1, :x1 => 1, :y2 => 22, :x2 => 80).strip.empty?
    # end
    #
    # # Check if we are on the login mainframe screen
    # def session_login?
    #   /#{ButlerMainframe::Settings.session_login_tag}/i === screen_title
    # end
    #
    # # Login to mainframe
    # # param1 user
    # # param2 password [sensible data]
    # def session_login user, password
    #   puts "Starting session login..." if @debug
    #   wait_session
    #   #inizializza_sessione
    #   raise "It was waiting session login map instead of: #{screen_title}" unless session_login?
    #   write user,      :y => 16, :x => 36
    #   write password,  :y => 17, :x => 36, :sensible_data => true
    #   do_enter
    # end
    #
    # # Check the label to know when we are on the cics selection map
    # def cics_selection?
    #   /#{ButlerMainframe::Settings.cics_selection_tag}/i === screen_title
    # end
    #
    # # On this map, we have to select the cics environment
    # # param1 cics usually is a number
    # def cics_selection cics
    #   puts "Starting selezione_cics..." if @debug
    #   wait_session
    #   raise "It was waiting cics selezion map instead of: #{screen_title}, message: #{catch_message}" unless cics_selection?
    #   write cics, :y => 23, :x => 14
    #   do_enter
    #   wait_session 1
    # end
    #
    # # Check the label to know when we are on the cics selection map
    # def company_menu?
    #   /#{ButlerMainframe::Settings.company_menu_tag}/i === screen_title
    # end
    #
    # # On this map, we have to select the cics environment
    # # param1 cics usually is a number
    # def company_menu
    #   puts "Starting company menu..." if @debug
    #   wait_session
    #   raise "It was waiting company menu map instead of: #{screen_title}, message: #{catch_message}" unless company_menu?
    #   write "01", :y => 24, :x => 43
    #   do_enter
    # end
    #
    # # Get the message line usually in the bottom of the screen
    # # You can define which rows provide the message:
    # #     :first_row                    => 22,
    # #     :last_row                     => 23
    # def catch_message options={}
    #   options = {
    #       :first_row                    => 22,
    #       :last_row                     => 23
    #   }.merge(options)
    #   scan(:y1 => options[:first_row], :x1 => 1, :y2 => options[:last_row], :x2 => 80).gsub(/\s+/, " ").strip
    # end
    #
    # # Get the abend message
    # def catch_abend
    #   scan(:y1 => 23, :x1 => 1, :y2 => 23, :x2 => 80)
    # end
    #
    # # Check if there was a malfunction on the mainframe
    # def abend?
    #   /DFHA/i === catch_abend
    # end
    #
    # # Get the title usually the first row
    # # You can change default option :rows to get more lines starting from the first
    # def screen_title options={}
    #   options = {
    #       :rows                      => 1
    #   }.merge(options)
    #   scan(:y1 => 1, :x1 => 1, :y2 => options[:rows], :x2 => 80)
    # end
  end
end

class ButlerMainframe::Host
  include Host3270::CustomFunctions
end