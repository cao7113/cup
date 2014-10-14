def app_server
  fetch(:app_server, :webrick)
end

#Dynamically get available app port
def checkin_app_port
  port = fetch(:app_port) #allow explictly specifid port
  return port if port
  port = 4000
  while true do
    #nc -z 检测端口是否被占用，占用返回 0
    cmd = "nc -z -n 127.0.0.1 #{port} "
    return port unless test cmd
    port += 1
  end
end

def pid_file
  fetch :pid_file, shared_path.join('tmp/pids/server.pid')
end

def port_file
  fetch :port_file, shared_path.join('tmp/port')
end

def log_file
  fetch :log_file, shared_path.join("log/#{stage}.log")
end

namespace :server do
  %w{start stop restart status url}.each do |action|
    Rake::Task.define_task(action) do
      invoke "server:#{app_server}:#{action}"
    end
  end

  task :boot

  task :hard_restart do
    invoke "server:#{app_server}:stop"
    invoke "server:#{app_server}:start"
  end

  desc "Get current server info"
  task :info do
    on roles(:app) do
      log "== Current app server: #{app_server}"
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
      execute :nc, "-z -v -n 127.0.0.1 4000-4500 2>&1|grep succeed || echo Nothing running!"
    end
  end

  task :next_port do
    on roles(:app) do
      port = checkin_app_port
      log "==>Next avaliable port: #{port}"
    end
  end
end
