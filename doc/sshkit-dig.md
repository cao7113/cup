# 深入研究sshkit


× 转化为可执行命令及脚本

  SSHKit::Command.new(:git, :push, :origin, :master).to_s

× 如何创建一个sshkit console？

* sshkit是一个独立的操作远程服务器的gem，可以与本地rake协作，capistrano3+就是rake+sshkit app
