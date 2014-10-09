def app_server
  fetch(:app_server, :webrick)
end

namespace :server do
  %w{start stop restart status url}.each do |action|
    Rake::Task.define_task(action) do
      invoke "server:#{app_server}:#{action}"
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
end

import "lib/server/#{app_server}.rake"
