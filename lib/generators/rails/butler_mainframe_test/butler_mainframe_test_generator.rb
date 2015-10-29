class Rails::ButlerMainframeTestGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  hook_for :test_framework
end
