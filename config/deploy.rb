# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, appname
set :repo_url, "http://localhost:6666/#{appname}"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, :master
set :format, :pretty
set :keep_releases, 3 #5
set :scm, :git

if railsapp?
  # Default value for linked_dirs is []
  set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets tmp/sessions vendor/bundle public/system}
  # Default value for :linked_files is []
  # set :linked_files, %w{config/secrets.yml}
end

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }


#Custom vars
set :runner, fetch(:runner, Etc.getlogin) #run this app as
set :sandbox, fetch(:sandbox, '/sandbox')
set :sandbox_shared, fetch(:sandbox_shared, File.join(fetch(:sandbox), 'shared'))
#env shared?

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

#for git check revision, ref: capistrano/git.rb in capistrano gem
module MyGitStrategy
  #include Capistrano::Git::DefaultStrategy #?
  def test
    test! " [ -f #{repo_path}/HEAD ] "
  end

  def check
    test! :git, :'ls-remote -h', repo_url
  end

  def clone
    git :clone, '--mirror', repo_url, repo_path
  end

  def update
    git :remote, :update
    #增加revision check，在deploy:updating的invoke "#{scm}:create_release"时调用！
    unless fetch(:not_check_revision)
      remote_revision = fetch_revision
      if remote_revision == fetch(:previous_revision)
        #context.execute :echo, "Error:  Stay on previous revision: #{remote_revision} in #{fetch(:branch)} branch!" 
        context.error " ====> Stay on previous revision: #{remote_revision} in #{fetch(:branch)} branch!" 
        exit(false) 
      end
    end
  end

  def release
    git :archive, fetch(:branch), '| tar -x -C', release_path
  end

  def fetch_revision
    context.capture(:git, "rev-parse --short #{fetch(:branch)}")
  end
end
set :git_strategy, MyGitStrategy

if require_bundler?
  #capistrano-bundler 
  #not use bundler bin/stubs for rails 4
  set :bundle_binstubs, false
  #set :bundle_path, -> { shared_path.join('bundle') }
  set :bundle_path, sandbox_shared_path.join('bundle')
  set :bundle_flags, '--deployment --quiet'
end

if railsapp?
  #capistrano-rails
  set :conditionally_migrate, true #check migration changes for performance, dig deep TODO !!!
end

namespace :deploy do

  #Hook the cap command?
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

  if railsapp?
    before :starting, :sync_config #尽早check，避免产生不必要的release
  end

  desc "Handle config update, how to use rsync?"
  task :upload_config do
    set :force_upload, true
    invoke 'deploy:sync_config'
  end

  if railsapp?
    #after :updating, :compile_assets_locally
    before :updated, "db:sqlite3:ensure_db"
  end

  desc 'Restart your application when deployment'
  task :restart do 
    if plainapp?
      on roles(:app) do #, in: :sequence, wait: 5 do
        # Your restart mechanism here, for example:
        # execute :touch, release_path.join('tmp/restart.txt')
        info "==================on restarting..."
      end
    else
      invoke 'backend:restart'
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
  task :purge=>'backend:stop' do
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
