# This software can perform your custom tasks on a 3270 emulator.
#
# Copyright (C) 2015  Marco Mastrodonato, m.mastrodonato@gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License

require 'core/configuration'
require 'core/configuration_dynamic'
require 'config/config'

module ButlerMainframe
  def self.root
    File.expand_path('../..', __FILE__)
  end
end

# TODO
# require 'i18n'
# I18n.load_path=Dir['config/locales/*.yml']
# I18n.locale = ButlerMainframe.configuration.language

env = Rails.env if defined?(Rails)
env ||= $ARGV[0] if $ARGV
env ||= "development"
debug = env == "development" ? true : false

# require the emulator sub class specified in the config.rb
require "mainframe/emulators/#{ButlerMainframe.configuration.host_gateway.to_s.downcase}"


%w(settings.yml private.yml).each  do |file|
  filepath = File.join(ButlerMainframe.root,'lib','config',file)
  ButlerMainframe::Settings.load!(filepath, :env => env) if File.exist? filepath
end

require 'mainframe/customization/active_record'
# puts "Extending Host class with #{Host3270::ActiveRecord}" if debug
# Use monkey patch for 1.8 compatibility
class ButlerMainframe::Host
  include Host3270::ActiveRecord
end

require 'mainframe/customization/generic_functions'
# puts "Extending Host class with #{Host3270::GenericFunctions}" if debug
class ButlerMainframe::Host
  include Host3270::GenericFunctions
end

if defined?(Host3270::CustomFunctions)
  # puts "Extending Host class with #{Host3270::CustomFunctions}" if debug
  class ButlerMainframe::Host
    include Host3270::CustomFunctions
  end
end

=begin
# To test in irb
require 'butler-mainframe'
host=ButlerMainframe::Host.new(debug: :full)
host.scan_page
host.navigate :next
=end