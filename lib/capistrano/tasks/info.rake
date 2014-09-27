namespace :info do

  desc "Revision current running in server"
  task :rev do
    on roles(:app).first do
      execute :cat, current_path.join('REVISION')
    end
  end

  desc "Try run_locally"
  task :try do
    run_locally do
      #execute :env 
      execute :pwd
      execute :ruby, '-v'
    end
    on roles(:app).first do
      execute :env 
      execute :ruby, '-v 2>&1'
    end
  end
end
