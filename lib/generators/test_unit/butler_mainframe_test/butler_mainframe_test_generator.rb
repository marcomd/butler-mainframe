require 'rails/generators/test_unit'
require 'rails/generators/resource_helpers'

module TestUnit # :nodoc:
  module Generators # :nodoc:
    class ButlerMainframeTestGenerator < Base # :nodoc:
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path('../templates', __FILE__)

      def create_test_file
        create_file "test/#{/^4\./ === Rails.version ? 'models' : 'unit'}/butler_mainframe_#{file_name}_test.rb",
                    <<-FILE.gsub(/^      /, '')
          require 'test_helper'

          class #{class_name}Test < ActiveSupport::TestCase
            test "Basic navigation" do
              params  = {:debug => true, :wait_debug => 0.5}
              host    = ButlerMainframe::Host.new(params)
              host.navigate :session_login
              assert host.session_login?, 'navigate :session_login => this is not the session login'

              host.navigate :next
              assert !host.session_login?, 'navigate :next => does not pass login screen'

              host.close_session
              assert host.action[:object] == nil, "Close session failed!"
            end

            test "#{class_name} navigation" do
              params  = {:debug => true, :wait_debug => 0.5}
              host    = ButlerMainframe::Host.new(params)

              #host.navigate :your_starting_screen
              # WRITE YOUR TEST

              host.close_session
              assert host.action[:object] == nil, "Close session failed!"
            end
          end
        FILE
      end

    end
  end
end