namespace :db do
  namespace :mongodb do
    task :install do
      on roles(:db) do
        if test "! which mongod &>/dev/null"
          sudo "apt-get -y install mongodb-server"
        end
      end
    end
  end
end
