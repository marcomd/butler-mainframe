ButlerMainframe.configure do |config|
  config.host_gateway   = :pcomm
  config.session_path   = '"C:/Program Files (x86)/IBM/Personal Communications/pcsws.exe" "C:/Users/XXXXXXXXXX/AppData/Roaming/IBM/Personal Communications/host3270.ws" /Q /H /S=A'
  config.session_tag    = 'A'
  config.timeout        = 6000
end

