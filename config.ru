require ::File.expand_path('../app', __FILE__)
run Rack::URLMap.new(
  '/' => PushUrl)
