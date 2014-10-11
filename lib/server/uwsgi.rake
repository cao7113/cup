namespace "server:uwsgi" do
  desc "Install uwsgi for ruby/rack app"
  task :install do
    on roles(:app) do
      if test "! gem query -in uwsgi >/dev/null"
        sudo "apt-get -y install libssl-dev libpcre3-dev"
        execute "gem install uwsgi -V"
      end
    end
  end

  task :add_to_emperor=>['emperor:install'] do
    on roles(:app) do
      ini_file = "uwsgi-#{appname}-#{stage}.ini"
      tmpfile = "/tmp/#{ini_file}"
      template_upload "templates/uwsgi.ini.erb", tmpfile
      sudo :mv, "-b #{tmpfile} #{fetch(:emperor_confd)}/#{ini_file}"
    end
  end

  task :add_to_nginx do
  end

  namespace :emperor do
    #where to put
    task :defaults do
      setifnil :emperor_name, 'emperor_dev'
      setifnil :emperor_user, runner
      setifnil :emperor_confd, "/etc/#{fetch(:emperor_name)}"
      setifnil :emperor_init, "/etc/init/#{fetch(:emperor_name)}.conf"
      setifnil :emperor_log, "/var/log/#{fetch(:emperor_name)}.log"
    end

    task :install=>[:defaults] do
      on roles(:app) do |role|
        if test "[ ! -d #{fetch(:emperor_confd)} ]"
          sudo "mkdir -p #{fetch(:emperor_confd)}"
          sudo "chown -R #{fetch(:emperor_user)}:#{fetch(:emperor_user)} #{fetch(:emperor_confd)}"

          template_upload 'templates/emperor.conf.erb', '/tmp/emperor.conf'
          sudo :mv, "-b /tmp/emperor.conf #{fetch(:emperor_init)}"

          sudo "touch #{fetch(:emperor_log)}"
          sudo "chown #{fetch(:emperor_user)}:#{fetch(:emperor_user)} #{fetch(:emperor_log)}"
        end
      end
    end

    task :uninstall=>[:defaults] do
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

    desc 'List all emperor apps'
    task :list=>[:defaults] do
      on roles(:app) do |role|
        sudo "ls -l #{fetch(:emperor_confd)}"
      end
    end
  end #of emperor namespace
end
