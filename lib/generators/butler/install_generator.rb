require 'rails/generators/base'
require File.join(File.dirname(__FILE__), '../butler_mainframe')

module Butler
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ::ButlerMainframe::Base

      desc "Installs ButlerMainframe configuration files"
      source_root File.expand_path('../../', __FILE__)
      class_option :emulator, :type => :string, :default => 'passport', :desc => "Choose your favorite emulator [passport]"

      def copy_to_local
        copy_file "butler/templates/custom_functions.rb", "config/initializers/butler_custom_functions.rb"
        copy_file "../config/settings.yml",               "config/butler.yml"
        copy_file "../config/private.yml",                "config/butler_private.yml"
        file = "config/initializers/butler.rb"
        copy_file "../config/config_EXAMPLE_#{options[:emulator]}.rb", file
        append_file file do
          <<-FILE.gsub(/^            /, '')
            raise "Define your host gateway in the rails initializer file!" unless ButlerMainframe.configuration.host_gateway
            require "mainframe/emulators/\#{ButlerMainframe.configuration.host_gateway.to_s.downcase}"

            %w(butler.yml butler_private.yml).each  do |file|
              filepath = File.join(Rails.root,'config',file)
              ButlerMainframe::Settings.load!(filepath, :env => Rails.env) if File.exist? filepath
            end
          FILE
        end
      end
    end
  end
end

