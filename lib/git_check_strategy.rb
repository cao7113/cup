#for git check revision, ref: capistrano/git.rb in capistrano gem
module GitCheckStrategy
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
        context.error " ====> 无代码变化: #{remote_revision} in #{fetch(:branch)} branch!" 
        exit
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
