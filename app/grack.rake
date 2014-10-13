namespace :app do
  task :defaults do
    setifnil :repos_root, '/data/repos'
    setifnil :db_root, '/data/grack/db'
    setifnil :log_root, shared_path.join('log')
  end

  #确保目录存在且可写！
  task :check=>:defaults do
    on roles(:app) do
      [:repos_root, :db_root, :log_root].each do |p|
        dir = fetch(p)
        sudo :mkdir, "-p #{dir}"
        sudo :chown, "-R #{runner}:#{runner} #{dir}"
      end 
    end
  end

  before 'deploy:starting', 'app:check'

  task :boot do
    binding.pry
    on roles(:app) do
      sudo_upload 'grack_conf.yml.erb', release_path.join('grack.yml')
    end
  end

  after 'deploy:updated', 'app:boot'
end
