require 'fileutils'

namespace :butler do
  namespace :mainframe do

    desc "Test butler mainframe gem"
    task(:test) do  |task_name, args|

      begin
        require 'butler-mainframe'

        # SLOW
        simple_iteration  :wait => 0.6

        # MEDIUM
        simple_iteration  :wait => 0.08

        # FAST (default 0.01 atm)
        simple_iteration

        puts "*** RAKE TESTS COMPLETE SUCCESSFULLY ***"
      rescue
        puts $!.message
        puts "--- RAKE TESTS FAILED ---"
        exit(9)
      end
    end

  end
end

def simple_iteration options={}
  options = {
      :host                       => nil,
      :wait                       => nil

  }.merge(options)

  puts
  puts "*** START ITERATION TEST WAIT #{options[:wait] || 'DEFAULT'} ***"
  params        = {:debug => false, :wait_debug => 0.5}
  params[:wait] = options[:wait] if options[:wait]
  host          = options[:host] || ButlerMainframe::Host.new(params)

  navigate host, :session_login
  str_screen1 = host.scan_page
  raise 'host.scan_page' if str_screen1.empty?
  raise 'navigate :session_login => this is not the session login' unless host.session_login?

  navigate host, :next
  str_screen2 = host.scan_page
  raise 'navigate :next from :session_login => the screen is not changed' if str_screen1 == str_screen2

  raise 'navigate :next => does not pass login screen' if host.session_login?

  navigate host, :next
  raise 'navigate :next => does not pass cics selection' if host.cics_selection?

  # Go back until the first screen
  navigate host, :session_login
  raise 'navigate :session_login => this is not the session login' unless host.session_login?

  raise "host.scan row failed"  unless host.scan(:y  => 1, :x  => 1, :len => ButlerMainframe::Host::MAX_TERMINAL_COLUMNS).size == ButlerMainframe::Host::MAX_TERMINAL_COLUMNS
  raise "host.scan area failed" unless host.scan(:y1 => 1, :x1 => 1, :y2  => 3, :x2 => ButlerMainframe::Host::MAX_TERMINAL_COLUMNS).size == (ButlerMainframe::Host::MAX_TERMINAL_COLUMNS * 3)

  navigate host, :back
  raise 'navigate :back from :session_login => this is not the session login' unless host.session_login?

  navigate host, :company_menu
  raise 'navigate :company_menu from :session_login => this is not the company menu' unless host.company_menu?

  navigate host, :next

  navigate host, :back

  navigate host, :back

  navigate host, :company_menu

  navigate host, :back

  navigate host, :back

  navigate host, :session_login

  navigate host, :cics_selection

  navigate host, :next

  navigate host, :back

  navigate host, :back

  navigate host, :session_login

  navigate host, :company_menu

  navigate host, :cics_selection

  navigate host, :session_login

  host.close_session
end

# Easy navigation for rake test
def navigate host, action
  msg = "Rake Navigate to #{action}: "
  print msg
  host.navigate action
  puts "#{' ' * (40 - msg.size).abs}OK"
end