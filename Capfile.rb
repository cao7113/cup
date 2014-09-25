#Note: this is a Rakefile like file for Capistrano
#  explicitly referred as: cap --rakefile _this_file_

#adjust by env or stage var?
require 'pry'
require 'pry-debugger'
#make a logger for capistrano?

#ENV['APP_NAME'] interface with world!
def appname
  @appname ||= ENV['APP_NAME']
end

def set_apptype
  @apptype = ENV['APP_TYPE'] #where to detect?
  unless @apptype and [:plain, :rack, :rails].include?(@apptype.to_sym)
    raise "Not support app type: #{@apptype}"
  end
  @apptype = @apptype.to_sym
end

set_apptype

def railsapp?
  @apptype == :rails
end

def plainapp?
  @apptype == :plain
end

def rackapp?
  [:rack, :rails].include?(@apptype)
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

#读取应用的设置信息？ 包括：
#是否需要读 本地的项目目录
#需不需要 bundler等

def require_bundler?
  ![:plain].include?(@apptype)
end

#TODO related to cap invocation location
def rake_root
  @rake_root ||= ENV['APP_ROOT'] #Rake.original_dir #location where rake or cap is invokied!
end

def root_cmd cmd
  "cd #{rake_root} && #{cmd} && cd - >/dev/null"
end

cup_root = File.dirname(__FILE__) 
lib_dir = File.join(cup_root, 'lib')
$:.unshift lib_dir unless $:.include?(lib_dir)
#Load some fixes or customization
require 'fix/sshkit/pretty'
require 'fix/rake/trace_output'

#require 'capistrano/console' #remote interactive console

# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#
# require 'capistrano/rbenv'
if require_bundler?
  require 'capistrano/bundler'
end
if railsapp?
  require 'capistrano/rails/migrations'
  ##use local assets precompilation to reduce server overload
  #require 'capistrano/rails/assets'
end

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
