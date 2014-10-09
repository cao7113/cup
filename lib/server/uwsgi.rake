namespace :load do
  task :defaults do
    set :uwsgi_emperor_conf_dir, '/etc/uwsgi'
    set :uwsgi_emperor_user, fetch(:runner)
    set :uwsgi_emperor_job_name, 'emperor'
    set :uwsgi_emperor_init, "/etc/init/#{fetch(:uwsgi_emperor_job_name)}.conf"
    set :uwsgi_emperor_log, "/var/log/#{fetch(:uwsgi_emperor_job_name)}.log"
  end
end

namespace "server:uwsgi" do
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
  end
end
