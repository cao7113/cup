# Cup -- Capistrano Up

 Better capistrano use for multiple unified ruby applications deployment.

项目开发理念：

* 部署工具应该可以独立于项目存在！

### Usage

* ./setup
* cup help
* cup init
* cup dev|test|prod|... deploy

### TODO

* 生成寄存于项目的cap文件，可以平移

### Problems

太繁琐，使用太不方便， 自动化水平太低！！！

重构 改造！

* where to invoke cap? in cup root or app root?

  now use cup root? why?

* run_locally problem?

### Ref

* https://github.com/peritor/webistrano
* https://github.com/railsware/caphub
* https://github.com/ayanko/caphub-slides
* http://www.talkingquickly.co.uk/2014/01/deploying-rails-apps-to-a-vps-with-capistrano-v3/
* https://github.com/TalkingQuickly/capistrano-3-rails-template

for uWSGI:

* https://github.com/elia/capistrano-uwsgi

for Puma: 

* https://github.com/tomjoro/puma_jungle_rbenv_cap3
* https://github.com/cao7113/capistrano-puma
