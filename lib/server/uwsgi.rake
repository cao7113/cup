namespace :load do
  task :defaults do
    set :uwsgi_role, :app
    set :uwsgi_env, -> { fetch(:rack_env, fetch(:rails_env, 'production')) }
    set :uwsgi_access_log, -> { File.join(shared_path, 'log', 'uwsgi_access.log') }
    set :uwsgi_error_log, -> { File.join(shared_path, 'log', 'uwsgi_error.log') }
    set :uwsgi_bin_uwsgi, `which uwsgi`.chomp

    #set :uwsgi_pid, -> { File.join(shared_path, 'tmp', 'pids', 'uwsgi.pid') }
    #set :uwsgi_bind, -> { File.join('unix://', shared_path, 'tmp', 'sockets', 'uwsgi.sock') }
    #set :uwsgi_init_active_record, false
    #set :uwsgi_preload_app, true
    # Rbenv and RVM integration
    #set :rbenv_map_bins, fetch(:rbenv_map_bins).to_a.concat(%w{ uwsgi uwsgictl })
    #set :rvm_map_bins, fetch(:rvm_map_bins).to_a.concat(%w{ uwsgi uwsgictl })
    
    ## emperor
    setifnil :uwsgi_emperor_conf_dir, '/etc/uwsgi'
    setifnil :uwsgi_emperor_user, fetch(:runner)
    setifnil :uwsgi_emperor_job_name, 'emperor'
    setifnil :uwsgi_emperor_init, "/etc/init/#{fetch(:uwsgi_emperor_job_name)}.conf"
    setifnil :uwsgi_emperor_log, "/var/log/#{fetch(:uwsgi_emperor_job_name)}.log"
  end
end

namespace "server:uwsgi" do
  desc "Test on remote"
  task :test do
    on roles(fetch(:uwsgi_role)) do |role|
      @role = role
      execute "echo $PATH"
      execute "echo #{fetch(:uwsgi_bin_uwsgi)}"
    end
  end

  desc "Install uwsgi for ruby/rack app"
  task :install do
    on roles(fetch(:uwsgi_role)) do |role|
      @role = role
      if test "! gem query -in uwsgi >/dev/null"
        sudo "apt-get -y install libssl-dev libpcre3-dev"
        execute "gem install uwsgi -V"
      end
    end
  end

  desc "Ps this application"
  task :ps do
    on roles(fetch(:uwsgi_role)) do |role|
      @role = role
      sudo "ps aux|grep #{fetch(:application)}"
    end
  end

  def template_uwsgi(from, to, role)
    [
        "config/#{from}-#{role.hostname}}.erb",
        "config/#{from}-#{fetch(:stage)}.erb",
        "config/#{from}.erb",
        "lib/capistrano/templates/#{from}-#{role.hostname}-#{fetch(:stage)}.rb",
        "lib/capistrano/templates/#{from}-#{role.hostname}-#{fetch(:stage)}.rb",
        "lib/capistrano/templates/#{from}-#{role.hostname}.rb",
        "lib/capistrano/templates/#{from}-#{fetch(:stage)}.rb",
        "lib/capistrano/templates/#{from}.rb.erb",
        "lib/capistrano/templates/#{from}.rb",
        "lib/capistrano/templates/#{from}.erb",
        File.expand_path("../../templates/#{from}.rb.erb", __FILE__),
        File.expand_path("../../templates/#{from}.erb", __FILE__)
    ].each do |path|
      if File.file?(path)
        erb = File.read(path)
        upload! StringIO.new(ERB.new(erb).result(binding)), to
        break
      end
    end
  end

  namespace :emperor do
    desc 'Install uWSGI emperor'
    task :install do
      on roles(fetch(:uwsgi_role)) do |role|
        @role = role
        if test "[ ! -d #{fetch(:uwsgi_emperor_conf_dir)} ]"
          sudo "mkdir -p #{fetch(:uwsgi_emperor_conf_dir)}"
          sudo "chown -R #{fetch(:uwsgi_emperor_user)}:#{fetch(:uwsgi_emperor_user)} #{fetch(:uwsgi_emperor_conf_dir)}"
          template_uwsgi 'uwsgi_emperor.conf', "#{fetch(:tmp_dir)}/uwsgi_emperor.conf", role
          sudo "mv -b #{fetch(:tmp_dir)}/uwsgi_emperor.conf #{fetch(:uwsgi_emperor_init)}"
          sudo "touch #{fetch(:uwsgi_emperor_log)}"
          sudo "chown #{fetch(:uwsgi_emperor_user)}:#{fetch(:uwsgi_emperor_user)} #{fetch(:uwsgi_emperor_log)}"
        end
      end
    end

    desc 'Uninstall uWSGI emperor'
    task :uninstall do
      on roles(fetch(:uwsgi_role)) do |role|
        #warning?
        if test "[ -d #{fetch(:uwsgi_emperor_conf_dir)} ]"
          #sudo "stop emperor"
          sudo "rm -f #{fetch(:uwsgi_emperor_init)} #{fetch(:uwsgi_emperor_log)}"
          sudo "rm -r #{fetch(:uwsgi_emperor_conf_dir)}"
        end
      end
    end

    %w[start stop restart status].each do |command|
      desc "#{command} uwsgi emperor"
      task "#{command}" do
        on roles(fetch(:uwsgi_role)) do
          sudo "#{command} #{fetch(:uwsgi_emperor_job_name)}"
        end
      end
    end

    desc 'List all emperor apps'
    task :list do
      on roles(fetch(:uwsgi_role)) do |role|
        sudo "ls -l #{fetch(:uwsgi_emperor_conf_dir)}"
      end
    end

    desc 'Backup emperor apps config'
    task :backup do
      on roles(fetch(:uwsgi_role)) do |role|
        sudo "cp -r #{fetch(:uwsgi_emperor_conf_dir)} #{fetch(:uwsgi_emperor_conf_dir)}-#{Time.now.to_s.gsub(/\D/, '')}"
      end
    end

    desc 'Setup this app into to emperor'
    task :setup do
      invoke "uwsgi:emperor:add"
      invoke "uwsgi:nginx:setup"
    end

    desc 'Add current project to the emperor'
    task :add do
      on roles(fetch(:uwsgi_role)), in: :sequence, wait: 1 do |role|
        @role = role
        template_uwsgi 'uwsgi.ini', "#{emperor_app_conf}", @role
      end
    end

    desc 'Remove current project from the emperor'
    task :remove do
      on roles(fetch(:uwsgi_role)) do
        sudo "rm -f '#{emperor_app_conf}'"
      end
      invoke "uwsgi:nginx:deconf"
    end

    desc 'Touch current project for reload'
    task :touch do
      on roles(fetch(:uwsgi_role)) do
        sudo "touch '#{emperor_app_conf}'"
      end
    end

    def emperor_app_conf
      "#{fetch(:uwsgi_emperor_conf_dir)}/#{fetch(:application)}-#{fetch(:stage)}.ini"
    end
  end #of emperor namespace
end
