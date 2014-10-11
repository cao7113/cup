require 'etc'

Sk = SSHKit

##extend dsl
def local_user
  Etc.getlogin
end

#Sk.config.format = :format #default
Sk.config.output_verbosity = :debug #use :debug as default instead of :info in gem 

## global ssh settings
Sk.config.backend.configure do |ssh|
  ssh.connection_timeout = 30
  ssh.pty = false #true
  ssh.ssh_options = {
    user: local_user,
    #keys: %w(/home/xxx/.ssh/id_rsa),
    forward_agent: true,
    auth_methods: %w(publickey)
    #auth_methods: %w(password)
  }
end
