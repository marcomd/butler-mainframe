module ButlerMainframe
  class Configuration
    attr_writer :allow_sign_up

    attr_accessor :language, :host_gateway, :browser_path, :session_url, :session_path, :session_tag, :timeout, :env

    def initialize
      @language       = :en
      @host_gateway   = nil
      @browser_path   = ""
      @session_url    = ""
      @session_path   = ""
      @session_tag    = nil
      @timeout        = 1000
      @env            = 'development'
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