namespace "server:webrick" do
  desc 'Start application'
  task :start do
    on roles(:app) do
      #How to encapsulate this function?
      port = case stage.to_s
        when 'dev'
          4100
        when 'test'
          4200
        else
          4300
        end
      while true do
        port0 = port
        port = capture :nc, "-z -n 127.0.0.1 #{port} || echo #{port}".chomp
        if port.strip.length > 0 
          break 
        else
          port = port0 + 1
        end
      end

      within release_path do
        if railsapp?
          execute :rails, "s -e #{rackenv} -d -p #{port}"
          execute :echo, "#{port} > tmp/port"
        else #plain, rack
          execute :echo, 'Nothing to do!'
        end
      end
    end
  end

  desc 'Display visit url'
  task :url do
    on roles(:app) do |host|
      port = capture(:cat, release_path.join('tmp', 'port')).chomp
      info "    Visit: http://#{host}:#{port}"
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:app), in: :sequence do #, wait: 1 do
      pidfile = shared_path.join("tmp/pids/server.pid")
      if test "[ -f #{pidfile} ]"
        set :old_pid, File.read(pidfile)
        execute :kill, "-9 #{fetch(:old_pid)}; true"
      end
    end
  end

  desc 'Show status'
  task :status do
    on roles(:app), in: :sequence do
      pidfile = shared_path.join("tmp/pids/server.pid")
      if test "[ -f #{pidfile} ]"
        set :old_pid, File.read(pidfile)
        puts capture(:kill, "-0 #{fetch(:old_pid)} && echo running with #{fetch(:old_pid)}|| echo Not running")
      else
        execute :echo, "Not running"
      end
    end
  end

  desc 'Restart'
  task :restart =>['server:webrick:stop', 'server:webrick:start']
end
