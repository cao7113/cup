namespace "server:uwsgi" do
  task :defaults do
    setifnil :app_uname, "#{appname}-#{stage}"
    invoke "server:uwsgi:emperor:defaults"
    setifnil :emperor_app_conf, "#{fetch(:emperor_confd)}/#{fetch(:app_uname)}.ini"

    setifnil :frontend_server, :nginx #none for port deployment
    case fetch(:frontend_server)
    when :nginx
      setifnil :socket_file, shared_path.join("tmp/sockets/uwsgi.sock")
      invoke "server:nginx:defaults"
      setifnil :nginx_app_conf, "#{fetch(:nginx_confd)}/uwsgi-#{fetch(:app_uname)}.conf"
      setifnil :nginx_domain_names, "#{fetch(:app_uname)}.lh #{appname}.#{stage}"
      setifnil :nginx_access_log, shared_path.join('log/nginx_access.log')
      setifnil :nginx_error_log, shared_path.join('log/nginx_error.log')
    end
  end

  desc "Install uwsgi for ruby/rack app"
  task :setup=>[:defaults] do
    on roles(:app) do
      if test "! rbenv which uwsgi &>/dev/null" #"! gem query -in uwsgi &>/dev/null"
        sudo "apt-get -y install libssl-dev libpcre3-dev"
        execute "gem install uwsgi -V"
      end
      invoke "server:uwsgi:emperor:install"
    end
  end

  task :add_to_emperor=>[:defaults] do
    on roles(:app) do
      if fetch(:frontend_server) == :none
        setifnil :app_port, checkin_app_port
        execute :echo, "#{fetch(:app_port)} > #{port_file}"
      end
      sudo_upload "uwsgi_conf.ini.erb", fetch(:emperor_app_conf) #if test "[ ! -f #{fetch(:emperor_app_conf)} ]" or ENV['force']
    end
  end

  task :add_to_nginx=>[:defaults] do
    on roles(:app) do
      if test "[ ! -f #{fetch(:nginx_app_conf)} ]"
        sudo_upload 'uwsgi_nginx.conf.erb', "#{fetch(:nginx_app_conf)}"
        invoke "server:nginx:reload"
      end
    end
  end

  task :start=>[:defaults] do
    invoke "server:uwsgi:add_to_emperor"
    case fetch(:frontend_server)
    when :nginx
      invoke "server:uwsgi:add_to_nginx"
    end
  end

  task :stop=>[:defaults] do
    on roles(:app) do
      sudo :rm, "-f #{fetch(:emperor_app_conf)}"
      case fetch(:frontend_server)
      when :nginx
        sudo :rm, "-f #{fetch(:nginx_app_conf)}"
        invoke "server:nginx:reload"
      end
    end
  end

  task :restart=>[:add_to_emperor] do
    on roles(:app) do
      if test "[ -f #{fetch(:emperor_app_conf)} ]"
        sudo :touch, fetch(:emperor_app_conf)
      else
        invoke :start
      end
    end
  end

  task :status=>:defaults do
    on roles(:app) do
      pid = capture(:cat, pid_file).chomp
      if test "kill -0 #{pid} &>/dev/null"
        log "==Running in pid: #{pid}"
      else
        log "==Not running now!"
      end
    end
  end

  task :url=>:defaults do
    on roles(:app) do
      case fetch(:frontend_server, :nginx)
      when :nginx
        log "==visit: #{fetch(:nginx_domain_names)}"
      else
        if test "[ -f #{port_file} ]"
          port = capture(:cat, port_file).chomp
          log "==visit: http://localhost:#{port}"
        else
          log "No port file: #{port_file}"
        end
      end
    end
  end

  namespace :emperor do
    task :defaults do
      setifnil :emperor_name, 'emperor'
      setifnil :emperor_user, runner
      setifnil :emperor_confd, "/etc/uwsgi"
      setifnil :emperor_init, "/etc/init/#{fetch(:emperor_name)}.conf"
      setifnil :emperor_log, "/var/log/#{fetch(:emperor_name)}.log"
    end

    task :install=>[:defaults] do
      on roles(:app) do |role|
        if test "[ ! -d #{fetch(:emperor_confd)} ]" or ENV['force']
          sudo "mkdir -p #{fetch(:emperor_confd)}"
          sudo "chown -R #{fetch(:emperor_user)}:#{fetch(:emperor_user)} #{fetch(:emperor_confd)}"
          sudo_upload 'uwsgi_emperor.conf.erb', fetch(:emperor_init)
          sudo "touch #{fetch(:emperor_log)}"
          sudo "chown #{fetch(:emperor_user)}:#{fetch(:emperor_user)} #{fetch(:emperor_log)}"
        end
      end
    end

    %w[start stop restart status].each do |command|
      desc "#{command} uwsgi emperor"
      task "#{command}"=>[:defaults] do
        on roles(:app) do
          sudo "#{command} #{fetch(:emperor_name)}"
        end
      end
    end

    desc 'List all emperor apps'
    task :list=>[:defaults] do
      on roles(:app) do |role|
        sudo "ls -lt #{fetch(:emperor_confd)}"
      end
    end

    task :clear=>[:defaults] do
      on roles(:app) do
        if test "[ -d #{fetch(:emperor_confd)} ]"
          sudo "stop #{fetch(:emperor_name)} &>/dev/null;true"
          sudo "rm -rf #{fetch(:emperor_confd)} #{fetch(:emperor_init)} #{fetch(:emperor_log)}"
        end
      end
    end

    task :backup=>[:defaults] do
      on roles(:app) do
        if test "[ -d #{fetch(:emperor_confd)} ]"
          sudo :rm, "-fr #{fetch(:emperor_confd)}.bak; true"
          sudo :cp, "-r #{fetch(:emperor_confd)} #{fetch(:emperor_confd)}.bak"
        end
      end
    end
  end #of emperor namespace
end
