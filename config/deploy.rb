# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, appname
set :repo_url, "http://localhost:6666/#{appname}"

#set some init
set :rbenv_root, '/opt/rbenv'

#ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, :master
set :format, :pretty
set :keep_releases, 3 #5
set :scm, :git

#set :locale, :zh

if railsapp?
  set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets tmp/sessions vendor/bundle public/system}
  #set :linked_files, %w{config/secrets.yml}
else
  set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets tmp/sessions vendor/bundle}
end

# set :log_level, :debug
# set :pty, true
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

set :runner, fetch(:runner, local_user)
set :sandbox, fetch(:sandbox, '/sandbox')
set :sandbox_shared, fetch(:sandbox_shared, File.join(fetch(:sandbox), 'shared'))

def runner
  fetch(:runner)
end

def sandbox_path
  Pathname.new(fetch(:sandbox))
end

def sandbox_shared_path
  sandbox_path.join('shared')
end

set :deploy_to, sandbox_path.join(fetch(:stage).to_s, fetch(:application))
set :git_strategy, GitCheckStrategy

if require_bundler?
  #not use bundler bin/stubs for rails 4
  set :bundle_binstubs, false
  #set :bundle_path, -> { shared_path.join('bundle') }
  set :bundle_path, sandbox_shared_path.join('bundle')
  set :bundle_flags, '--deployment' #--quiet
end

if railsapp?
  set :conditionally_migrate, true
end

namespace :deploy do
  before :starting, :start_timer do
    @start_time = Time.now
  end
  after :finished, :end_timer do
    puts "#" * 80
    puts "    Has taken: #{Time.now - @start_time}s in total!"
  end

  desc "Make sure deploy_to dir writable"
  task :check_dirs do
    dirs = [fetch(:sandbox), fetch(:sandbox_shared)]
    on roles(:app) do
      sudo :mkdir, "-pv", dirs.join(' ')
      sudo :chown, "-R #{runner}:#{runner} #{dirs.join(' ')} "
    end
  end
  before :starting, :check_dirs

  desc 'Sync config use scp'
  task :sync_config do
    if prodlike?
      approot_run do
        set :linked_files, fetch(:linked_files, []).push('config/application.yml')
        invoke 'deploy:check:make_linked_dirs' #for linked_files config
        on roles(:app) do
          (fetch(:linked_files)||[]).each do |f|
            target_file = File.join(shared_path, f)
            if test("[ ! -e #{target_file} ]") || fetch(:force_upload) 
              upload! 'config/application.yml', target_file
            end
          end
        end
      end
    end 
  end

  if railsapp?
    before :starting, :sync_config #尽早check，避免产生不必要的release
  end

  desc "Handle config update, how to use rsync?"
  task :upload_config do
    set :force_upload, true
    invoke 'deploy:sync_config'
  end

  if railsapp?
    after :updating, :compile_assets_locally
    before :updated, "db:sqlite3:ensure_db"
  end

  desc 'Restart your application when deployment'
  task :restart do 
    if plainapp?
      on roles(:app) do #, in: :sequence, wait: 5 do
        info "====Replace restart way!"
      end
    else
      invoke 'server:restart'
    end
  end

  after :publishing, :restart
  #after :restart, :clear_cache do
    #on roles(:web), in: :groups, limit: 3, wait: 10 do
      ## Here we can do anything such as:
      ## within release_path do
      ##   execute :rake, 'cache:clear'
      ## end
    #end
  #end
  
  #check status task after finished and notify!!!

  desc "Purge deployment state"
  task :purge=>'server:stop' do
    on roles(:app) do
      execute :rm, "-rf", releases_path
      execute :rm, "-rf", current_path
      execute :rm, "-rf", repo_path #in case switch repo_url
      execute :rm, "-rf", deploy_to.join("revisions.log")
      #keep shared_path to save db or bundle cache
    end
  end

  desc "Purge then deploy"
  task :cold=> ['deploy:purge', 'deploy']
end
