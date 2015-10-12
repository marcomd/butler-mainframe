require 'fileutils'

namespace :butler do
  namespace :mainframe do

    desc "Test butler mainframe gem"
    task(:test) do  |task_name, args|

      begin
        require 'butler-mainframe'
        host = ButlerMainframe::Host.new
        str_screen1 = host.scan_page
        raise 'host.scan_page' if str_screen1.empty?
        host.navigate :next
        str_screen2 = host.scan_page
        raise 'host.navigate :next' if str_screen1 == str_screen2
        host.close_session

      rescue
        puts $!.message
        exit(9)
      end
    end

  end
end