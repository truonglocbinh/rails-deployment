root = "/home/locbinh/myapp/rails-deployment/current"
working_directory root

pid "#{root}/tmp/pids/unicorn.pid"

stderr_path "#{root}/log/unicorn.log"
stdout_path "#{root}/log/unicorn.log"

worker_processes 2
timeout 30
preload_app true

listen '/tmp/unicorn.spui.sock', backlog: 64

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
  old_pid = '#{root}/tmp/pids/unicorn.pid.oldbin'
if File.exists?(old_pid) && server.pid != old_pid
  begin
    Process.kill("QUIT", File.read(old_pid).to_i)
  rescue Errno::ENOENT, Errno::ESRCH
    # someone else did our job for us
  end
end

end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end

# Force the bundler gemfile environment variable to
# reference the capistrano "current" symlink
before_exec do |_|
  ENV['BUNDLE_GEMFILE'] = File.join(root, 'Gemfile')
end

