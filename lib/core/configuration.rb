module ButlerMainframe
  class Configuration
    attr_writer :allow_sign_up

    attr_accessor :language, :host_gateway, :browser_path, :session_path

    def initialize
      @language       = :en
      @host_gateway   = nil
      @browser_path   = ""
      @session_path   = ""
    end

  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield configuration
  end
end