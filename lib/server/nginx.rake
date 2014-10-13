namespace "server:nginx" do
  task :defaults do
    setifnil :nginx_confd, "/etc/nginx/conf.d"
  end

  %w(start stop restart reload status configtest force-reload upgrade).each do |act| 
    desc "#{act} nginx service"
    task "#{act}" do
      on roles(:app) do |role|
        sudo :service, "nginx #{act}"
      end
    end
  end

  task :list=>[:defaults] do
    on roles(:app) do |role|
      execute :ls, "-lt #{fetch(:nginx_confd)}"
    end
  end
end
