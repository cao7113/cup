# Deployment Steps with Capistrano

* edit Gemfile to use capistrano-rails gem
* bundle install
* cap install STAGES=test,staging,production
* config Capfile, config/deploy.rb, config/deploy/*.rb

### Stages

* dev:         local dev mode, quick check cap flow, development branch
* test:        local test mode, test branch
* prod:        local production mode, production branch

Build two production-based environments! RAILS_ENV=stating|online
* staging:     vm mock vps, production branch
* online:      vps online, production branch

Note: Capistrano mainly used for production deployment !!! not development/test mode!

### DB setting for Sqlite3

using shared_path/db.sqlite3

### Problems

* compile assets locally?? 

* run_locally within bug???

* 动态检查git 分支是否存在？ 最后智能fallback到master分支？

* 为避免重复，如何合理的抽成一个gem？？？？ 系统级工具，只需要appname，就可以默认部署???

  利用 cap --rakefile xxx

* cap-uwsgi, unicorn

  prod, nginx

* 为避免麻烦，默认选取master分支?

* config/deploy.rb, config/deploy/_stage_.rb 哪个先被加载？ 变量是否被覆盖？

  config/deploy.rb相当于默认设置
  _stage_.rb进行针对环境的适配

* assets host --> name server
* rails app --> rack app
* 根据请求自动激活，否则进入休眠状态，以便在本地可以节约cpu资源
* 增加对应stage的rails env, stage的私密数据保护！

* 什么时间可以拿到fetch(:current_revision)的值？

  after :updating, xxx

* rails assets complie locally!! 

  智能,明确,本地预编译

* 配合puppet/chef部署

* ports智能管理

  通过netcat命令探测是否已经被占用，使用范围： 4010 -- 5000

* 在运行task时能否显示当前运行task name！！！

  如何获取running flow图，在关系复杂时可以追踪问题源！
  cap --prereqs xxx

* 像config/{database.yml,secrets.yml} 的配置问题
  
  使用secrets.yml+Figaro+Conf

* rake flow 控制
 next/break ??
 false机制！

* 检查repo代码是否更新，当没更新时，不要一再发布而是提示，省去不必要的发布步骤

  智能发布， 除非指定 not_check_revision

* sshkit pretty formatter for 显示中文错误

方案1： require lib/sshkit/fix/* in Capfile
方案2： log_level 不用debug(默认)

* SSHKit::Runner::ExecuteError: Exception while executing on host localhost: git exit status: 2
git stdout: Nothing written
git stderr: fatal: Not a valid object name
tar: 它似乎不像是一个 tar 归档文件
tar: 由于前次错误，将以上次的错误状态退出

因为没有对应的git分支造成的！
