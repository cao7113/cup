#site type: plain, static(has nginx config)
namespace :site do
  task :deploy do
    on roles(:web) do
      if test "[ -d #{deploy_to} ]"
        execute "cd #{deploy_to} && git pull" 
      else
        execute :git, "clone #{repo_url} #{deploy_to}" 
        invoke "site:start"
      end
    end
  end

  task :purge do
    on roles(:web) do
      execute :rm, "-fr #{deploy_to}" 
    end
  end

  task :start do
    next unless fetch(:site_type) == :static 
    invoke "server:nginx:defaults"
    on roles(:web) do
      execute :mkdir, '-pv', shared_path.join('log')
      conf_file = "#{fetch(:nginx_confd)}/#{appname}.conf"
      sudo_upload "nginx_static.conf.erb", conf_file 
      invoke "server:nginx:reload"
    end
  end

  task :stop do
    next unless fetch(:site_type) == :static 
    on roles(:web) do
      invoke "server:nginx:defaults"
      on roles(:web) do
        conf_file = "#{fetch(:nginx_confd)}/#{appname}.conf"
        if test "[ -e #{conf_file} ]"
          sudo :rm, "-fr #{conf_file}"
          invoke "server:nginx:reload"
        end
      end
    end
  end
end

task :site=>'site:deploy'
