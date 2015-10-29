# This software can perform your custom tasks on a 3270 emulator.
#
# Copyright (C) 2015  Marco Mastrodonato, m.mastrodonato@gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License

require 'core/configuration'
require 'core/configuration_dynamic'

module ButlerMainframe
  def self.root
    File.expand_path('../..', __FILE__)
  end
end

# This project use monkey patch for 1.8 compatibility
require 'mainframe/host_base'

# puts "Butler Mainframe #{defined?(Rails) ? 'with' : 'without'} Rails" #DEBUG
if defined?(Rails)
  # Rails use own configuration file into initializers folder

  # This module adds additional methods useful only for projects rails
  require 'mainframe/customization/active_record'
  class ButlerMainframe::HostBase
    include ButlerMainframe::ActiveRecord
  end
else
  # ...if it is not a rails project load configuration file
  require 'config/config'

  # require the emulator sub class specified in the config.rb
  raise "Define your host gateway in the configuration file!" unless ButlerMainframe.configuration.host_gateway
  require "mainframe/emulators/#{ButlerMainframe.configuration.host_gateway.to_s.downcase}"

  %w(settings.yml private.yml).each  do |file|
    filepath = File.join(ButlerMainframe.root,'lib','config',file)
    ButlerMainframe::Settings.load!(filepath, :env => ButlerMainframe.configuration.env) if File.exist? filepath
  end
end