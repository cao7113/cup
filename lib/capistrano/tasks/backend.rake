#TODO Thin, unicorn, uwsgi, puma
#Move into lib/capistrano/tasks or ~/.xxx
namespace :backend do

  task :defaults do
    set(:appserver, fetch(:appserver, :webrick))
  end

  %w{start stop restart status url}.each do |action|
    Rake::Task.define_task(action) do
      invoke "backend:defaults"
      invoke "backend:#{fetch(:appserver)}:#{action}"
    end
  end

  #From this StackOverflow answer:
  #You seem to be looking for a port scanner such as nmap or netcat, both of which are available for Windows, Linux, and Mac OS X.
  #For example, check for telnet on a known ip:
    #nmap -A 192.168.0.5/32 -p 23
  #For example, look for open ports from 20 to 30 on host.example.com:
    #nc -z host.example.com 20-30
  desc 'Scan ports'
  task :scan do
    on roles(:app) do
      #nc -zw3 domain.tld 22 && echo "opened" || echo "closed"
      execute :nc, "-z -v -n 127.0.0.1 4100-4500 2>&1|grep succeed || echo Nothing running!"
    end
  end

  namespace :webrick do

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
          execute :rails, "s -e #{rackenv} -d -p #{port}"
          execute :echo, "#{port} > tmp/port"
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
    task :restart =>['backend:webrick:stop', 'backend:webrick:start']
  end
end
