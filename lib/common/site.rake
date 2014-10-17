#site type: plain, static(has nginx config)
def site_path
  fetch(:site_path)
end

namespace :site do
  task :defaults do
    setifnil :site_path, deploy_to.join('current')
  end

  task :deploy=>:defaults do
    on roles(:web) do
      if test "[ -d #{site_path} ]"
        execute "cd #{site_path} && git pull" 
      else
        execute :git, "clone #{repo_url} #{site_path}" 
        invoke "site:start"
      end
    end
  end

  task :purge do
    on roles(:web) do
      execute :rm, "-fr #{deploy_to}" 
    end
  end

  task :start=>:defaults do
    next unless fetch(:site_type) == :static 
    invoke "server:nginx:defaults"
    on roles(:web) do
      execute :mkdir, '-pv', shared_path.join('log')
      conf_file = "#{fetch(:nginx_confd)}/#{appname}.conf"
      sudo_upload "nginx_static.conf.erb", conf_file 
      invoke "server:nginx:reload"
    end
  end

  task :stop=>:defaults do
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
