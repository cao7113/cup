namespace "server:nginx" do
  task :defaults do
    setifnil :nginx_confd, "/etc/nginx/conf.d"
    setifnil :domain_postfix, 'lh'
    setifnil :nginx_domain_names, "#{stage}-#{appname}.#{fetch(:domain_postfix, 'lh')}"
    setifnil :nginx_access_log, shared_path.join('log/nginx_access.log')
    setifnil :nginx_error_log, shared_path.join('log/nginx_error.log')
  end

  %w(start stop restart reload status configtest force-reload upgrade).each do |act| 
    desc "#{act} nginx service"
    task "#{act}" do
      on roles(:web) do |host|
        sudo :service, "nginx #{act}"
      end
    end
  end

  task :list=>[:defaults] do
    on roles(:web) do |host|
      execute :ls, "-lt #{fetch(:nginx_confd)}"
    end
  end
end
