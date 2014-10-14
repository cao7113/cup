namespace "server:webrick" do
  desc 'Start application'
  task :start do
    on roles(:app) do
      port = checkin_app_port
      within release_path do
        if railsapp?
          execute :rails, "s -e #{rackenv} -d -p #{port}"
          execute :echo, "#{port} > #{port_file}"
        else #plain, rack
          execute :echo, 'Nothing to do!'
        end
      end
    end
  end

  desc 'Display visit url'
  task :url do
    on roles(:app) do |host|
      port = capture(:cat, port_file).chomp
      log "==>  Visit: http://#{host}:#{port}"
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:app), in: :sequence do #, wait: 1 do
      pidfile = pid_file
      if test "[ -f #{pidfile} ]"
        set :old_pid, File.read(pidfile)
        execute :kill, "-9 #{fetch(:old_pid)}; true"
      end
    end
  end

  desc 'Show status'
  task :status do
    on roles(:app), in: :sequence do
      pidfile = pid_file
      if test "[ -f #{pidfile} ]"
        set :old_pid, File.read(pidfile)
        puts capture(:kill, "-0 #{fetch(:old_pid)} && echo running with #{fetch(:old_pid)}|| echo Not running")
      else
        execute :echo, "Not running"
      end
    end
  end

  desc 'Restart'
  task :restart =>['server:hard_restart']
end
