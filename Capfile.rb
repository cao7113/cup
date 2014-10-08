#Note: this is a Rakefile like file for Capistrano
#  explicitly referred as: cap --rakefile _this_file_

#adjust by env or stage var?
require 'pry'
require 'pry-debugger'
#make a cup logger write to /sandbox/deployment.log

require 'bundler'

def approot
  @approot ||= ENV['APP_ROOT']||Dir.pwd
end

#因是在cup root中执行cap，修复需要在项目中运行的路径问题
def approot_run 
  return unless block_given?
  begin
    pwd = Dir.pwd
    Dir.chdir approot
    yield
  ensure
    Dir.chdir pwd
  end
end

#location where rake or cap is invokied!
#traditional cap usage, same with approot
def rake_root
  Rake.original_dir 
end

def appname
  @appname ||= ENV['APP_NAME']||File.basename(approot)
end

#read from .cuprc???
def apptype
  @apptype ||= (ENV['APP_TYPE']||'plain').to_sym
end

def railsapp?
  apptype == :rails
end

def plainapp?
  apptype == :plain
end

def rackapp?
  [:rack, :rails].include?(apptype)
end

def stage
  fetch(:stage)
end

def rackenv
  fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
end

def prodlike?
  rackenv and [:production, :staging, :online].include?(rackenv.to_sym)
end

def require_bundler?
  File.exist?(File.join(approot, 'Gemfile'))
end

cup_root = File.dirname(__FILE__) 
lib_dir = File.join(cup_root, 'lib')
$:.unshift lib_dir unless $:.include?(lib_dir)
require 'fix/sshkit/pretty'
require 'fix/rake/trace_output'
require 'git_check_strategy'

require 'capistrano/console' #remote interactive console
require 'capistrano/setup' # Load DSL and Setup Up Stages
require 'capistrano/deploy' # Includes default deployment tasks

# require 'capistrano/rbenv'
if require_bundler?
  require 'capistrano/bundler'
end
if railsapp?
  require 'capistrano/rails/migrations'
  #require 'capistrano/rails/assets' #local assets precompilation to reduce server overload
end

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
import 'lib/backend/init.rake'
