namespace :info do

  desc "Revision current running in server"
  task :rev do
    on roles(:app).first do
      execute :cat, current_path.join('REVISION')
    end
  end

  desc "Try run_locally"
  task :try do
    #on roles(:app).first do
      ##execute :env 
      ##execute :ruby, '-v'
      #execute :pwd
    #end

    #run_locally do
      ##execute :env
      #execute "pwd && bundle show && pwd" #命令执行的时候还是在 oridingal dir？
      #execute :pwd
    #end
    #sh "(cd ~/dev/railslab && bundle show)"
    binding.pry
    sh "cd ~ && bundle show"
  end
end
