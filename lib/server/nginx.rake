namespace "server:nginx" do
  task :defaults do
    setifnil :nginx_confd, "/etc/nginx/conf.d"
  end

  %w(status start stop restart reload configtest force-reload upgrade).each do |act| 
    desc "#{act} nginx service"
    task "#{act}" do
      on roles(fetch(:uwsgi_role)) do |role|
        sudo :service, "nginx #{act}"
      end
    end
  end
end
