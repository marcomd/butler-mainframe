ButlerMainframe.configure do |config|
  config.host_gateway   = :passport
  config.browser_path   = 'c:/Program Files (x86)/Internet Explorer/iexplore.exe'
  config.session_url    = 'https://localhost/zephyr/Ecomes.zwh?sessionprofile=3270dsp/Sessions/host3270'
  config.session_tag    = 1
  config.timeout        = 6000
end

