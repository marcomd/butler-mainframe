require 'rails/generators/base'

module Butler
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Installs ButlerMainframe configuration files"
      source_root File.expand_path('../../', __FILE__)

      def copy_to_local
        copy_file "butler/templates/custom_functions.rb", "config/initializers/butler_custom_functions.rb"
        copy_file "../config/settings.yml", "config/butler.yml"
        file = "config/initializers/butler.rb"
        copy_file "../config/config.rb", file
        append_file file do
          <<-FILE.gsub(/^            /, '')
            ButlerMainframe::Settings.load!(File.join(Rails.root,'config','butler.yml'), :env => Rails.env)
          FILE
        end
      end
    end
  end
end

