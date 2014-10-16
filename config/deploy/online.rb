set :repo_url, "http://localhost:8888/#{appname}"
set :rack_env, 'online'
set :runner, 'doger' #TODO READ FROM ENV
server '128.199.149.155', user: runner, roles: %w{web app db}

set :app_server, :uwsgi
set :frontend_server, :nginx #none

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
set :ssh_options, {
  keys: %w(/home/cao/.ssh/id_rsa),
  forward_agent: true, #false,
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
