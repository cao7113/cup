namespace :deploy do
  desc "compiles assets locally then rsync, simple and bugless!"
  task :compile_assets_locally_simple do
    set :enable_locally_compile_assets, fetch(:enable_locally_compile_assets, %w{production vm online}.include?(fetch(:rails_env).to_s))
    if fetch(:enable_locally_compile_assets)
      #问题： 每次发布都会进行编译！！！
      run_locally do
        execute "bundle exec rake assets:precompile"
      end
      on roles(:app) do |host|
        rsync_upload host, 'public/assets/',  "#{release_path}/public/assets/"
      end
      run_locally do
        execute "rm -fr public/assets"
      end
    end
  end
end
