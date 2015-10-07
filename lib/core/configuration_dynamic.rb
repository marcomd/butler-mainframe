require 'yaml'
require 'vendor/deep_symbolize'

module ButlerMainframe
  # we don't want to instantiate this class - it's a singleton,
  # so just keep it as a self-extended module
  extend self

  # Appdata provides a basic single-method DSL with .parameter method
  # being used to define a set of available settings.
  # This method takes one or more symbols, with each one being
  # a name of the configuration option.
  def parameter(*names)
    names.each do |name|
      attr_accessor name

      # For each given symbol we generate accessor method that sets option's
      # value being called with an argument, or returns option's current value
      # when called without arguments
      define_method name do |*values|
        value = values.first
        value ? self.send("#{name}=", value) : instance_variable_get("@#{name}")
      end
    end
  end

  # And we define a wrapper for the configuration block, that we'll use to set up
  # our set of options
  def configure_on_the_fly(&block)
    instance_eval &block
  end
  
  module Settings
    # again - it's a singleton, thus implemented as a self-extended module
    extend self

    @_settings = {}
    attr_reader :_settings

    # This is the main point of entry - we call Settings.load! and provide
    # a name of the file to read as it's argument. We can also pass in some
    # options, but at the moment it's being used to allow per-environment
    # overrides in Rails
    def load!(filename, options = {})
      newsets = YAML::load_file(filename)
      newsets.extend DeepSymbolizable
      newsets = newsets.deep_symbolize
      newsets = newsets[options[:env].to_sym] if options[:env] && \
                                                 newsets[options[:env].to_sym]
      deep_merge!(@_settings, newsets)
    end

    # Deep merging of hashes
    # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
    def deep_merge!(target, data)
      merger = proc{|key, v1, v2|
        Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      target.merge! data, &merger
    end

    def method_missing(name, *args, &block)
      @_settings[name.to_sym] ||
      fail(NoMethodError, "unknown configuration root #{name}", caller)
    end

  end
end