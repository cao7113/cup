namespace "server:uwsgi" do
  task :defaults=>['server:nginx:defaults'] do
    setifnil :app_uname, "#{appname}-#{stage}"
    setifnil :socket_file, shared_path.join("tmp/sockets/uwsgi.sock")

    #app nginx settings
    setifnil :nginx_domain_names, "#{fetch(:app_uname)}.lh #{appname}.#{stage}"
    setifnil :nginx_access_log, shared_path.join('log/nginx_access.log')
    setifnil :nginx_error_log, shared_path.join('log/nginx_error.log')
  end

  desc "Install uwsgi for ruby/rack app"
  task :install do
    on roles(:app) do
      if test "! gem query -in uwsgi >/dev/null"
        sudo "apt-get -y install libssl-dev libpcre3-dev"
        execute "gem install uwsgi -V"
      end
    end
  end

  task :add_to_emperor=>['emperor:init', :defaults] do
    on roles(:app) do
      if test "[ ! -f #{fetch(:emperor_confd)}/uwsgi-#{fetch(:app_uname)}.ini ]"
        sudo_upload "uwsgi.ini.erb", "#{fetch(:emperor_confd)}/uwsgi-#{fetch(:app_uname)}.ini"
      end
    end
  end

  task :rm_from_emperor=>['emperor:init', :defaults] do
    on roles(:app) do
      sudo :rm, "-f #{fetch(:emperor_confd)}/uwsgi-#{fetch(:app_uname)}.ini"
    end
  end

  task :add_to_nginx=>[:defaults] do
    on roles(:app) do
      if test "[ ! -f #{fetch(:nginx_confd)}/uwsgi-#{fetch(:app_uname)}.conf ]"
        sudo_upload 'uwsgi_nginx.conf.erb', "#{fetch(:nginx_confd)}/uwsgi-#{fetch(:app_uname)}.conf"
        sudo :service, "nginx reload"
      end
    end
  end

  task :init=>[:defaults] do
    invoke "server:uwsgi:add_to_emperor"
    invoke "server:uwsgi:add_to_nginx"
  end

  task :start=>[:init]

  task :stop=>:rm_from_emperor

  task :restart=>[:add_to_emperor] do
    on roles(:app) do
      sudo :touch, "#{fetch(:emperor_confd)}/uwsgi-#{fetch(:app_uname)}.ini"
    end
  end

  task :status=>[:defaults] do
    #check
  end

  namespace :emperor do
    task :defaults do
      setifnil :emperor_name, 'emperor'
      setifnil :emperor_user, runner
      setifnil :emperor_confd, "/etc/uwsgi"
      setifnil :emperor_init, "/etc/init/#{fetch(:emperor_name)}.conf"
      setifnil :emperor_log, "/var/log/#{fetch(:emperor_name)}.log"
    end

    task :init=>[:defaults, "server:uwsgi:install"] do
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

    desc 'List all emperor apps'
    task :list=>[:defaults] do
      on roles(:app) do |role|
        sudo "ls -l #{fetch(:emperor_confd)}"
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

    %w[start stop restart status].each do |command|
      desc "#{command} uwsgi emperor"
      task "#{command}"=>[:defaults] do
        on roles(:app) do
          sudo "#{command} #{fetch(:emperor_name)}"
        end
      end
    end
  end #of emperor namespace
end
