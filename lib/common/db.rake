namespace :db do
  desc <<-Desc
Force migrate with explictly no conditionally_migrate
当deploy出现错误时，会导致此比较机制不好使，需要明确手工运行！
  Desc
  task :migrate do 
    set :conditionally_migrate, false
    invoke "deploy:migrate"
  end

  namespace :sqlite3 do
    desc 'Init db file for sqlite3'
    task :init do
      set :sqlite3_db_file, fetch(:sqlite3_db_file, shared_path.join('db.sqlite3'))
      on roles(:db) do
        execute :touch, fetch(:sqlite3_db_file)
      end
    end

    desc 'Symlink current db file to stage db file'
    task :link_db do
      on roles(:db) do
        within release_path do
          execute :ln, '-s', fetch(:sqlite3_db_file), "db/#{rackenv}.sqlite3"
        end
      end
    end

    desc "Ensure db ok"
    task :ensure_db=>['db:sqlite3:init', 'db:sqlite3:link_db']
  end
end
