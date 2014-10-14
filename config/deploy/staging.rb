set :repo_url, "http://10.0.2.2:6666/#{appname}"
set :rack_env, 'staging'

#vagrant ssh-config
#Host cup-vm
  #HostName 127.0.0.1
  #User vagrant
  #Port 2222
  #UserKnownHostsFile /dev/null
  #StrictHostKeyChecking no
  #PasswordAuthentication no
  #IdentityFile /home/cao/.vagrant.d/insecure_private_key
  #IdentitiesOnly yes
  #LogLevel FATAL
#access by host_hash['User']
def vm_host_hash
  return @vm_host if @vm_host
  run_locally do
    config = capture("vagrant ssh-config --host cup-vm").split(/\n/)
    @vm_host = config.inject({}) do |r, l| 
      if l.strip.length > 0
        k, v = l.strip.split(/\s+/)
        r[k] = v
      end
      r
    end
    @vm_host['VmHostUrl'] = "#{@vm_host['User']}@#{@vm_host['HostName']}:#{@vm_host['Port']}"
    @vm_host
  end
end

set :runner, vm_host_hash['User'] 
server vm_host_hash['VmHostUrl'], user: runner, roles: %w{web app db}

set :app_server, :uwsgi
set :frontend_server, :none

task :ssh_test do
  #puts vm_host_hash
  on roles(:app) do |host|
    execute :whoami
    binding.pry
  end
end

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
set :ssh_options, {
  keys: [vm_host_hash['IdentityFile']],
  forward_agent: true,
  auth_methods: %w(publickey password)
}
#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
