ButlerMainframe.configure do |config|
  config.host_gateway   = :x3270
  config.session_path   = '"C:/Program Files (x86)/wc3270/ws3270.exe" YOUR_HOST_IP -model 2 --'
  config.timeout        = 5 # In seconds
end

