proj_root = File.expand_path('..', __FILE__)
puts "root: #{proj_root}"
worker_processes 2
working_directory proj_root

stderr_path "#{proj_root}/tmp/unicorn.log"
stdout_path "#{proj_root}/tmp/unicorn.log"

preload_app false
timeout 30

pid "#{proj_root}/tmp/unicorn.pid"
listen File.expand_path('tmp/unicorn.sock', proj_root), :backlog => 64
