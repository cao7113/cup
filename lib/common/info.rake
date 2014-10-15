namespace :info do

  task :ping do
    on roles(:app) do
      execute :uptime
      execute :whoami
      execute :echo, '==pong'
    end
  end

  desc "Revision current running in server"
  task :rev do
    on roles(:app).first do
      puts capture(:cat, current_path.join('REVISION'))
    end
  end

  desc "Try run_locally"
  task :try do
    run_locally do
      #execute :env 
      execute :pwd
      execute :ruby, '-v'
    end
    approot_run do
      puts "====pwd: #{Dir.pwd}"
      on roles(:app).first do
        execute :env 
        execute :pwd 
        execute :ruby, '-v 2>&1'
      end
    end
  end

  desc "rake run assets precompile"
  task :compile_assets do
    approot_run do
      run_locally do
        # Ref: bundle help exec
        # make sure that if bundler is invoked in the subshell, it uses the same Gemfile (by setting BUNDLE_GEMFILE)
        # Way1:
        #execute "BUNDLE_GEMFILE=#{approot}/Gemfile bundle show"
        #execute "BUNDLE_GEMFILE=#{approot}/Gemfile bundle exec rake assets:precompile"
        # Way2:
        Bundler.with_clean_env do
          #execute "bundle show"
          execute "bundle exec rake assets:precompile"
        end
      end
    end
  end
end
