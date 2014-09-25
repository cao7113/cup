set :rack_env, 'development'
server 'localhost', user: runner, roles: %w{web app}, primary: true #, my_property: :my_value

if require_bundler?
#capistrano-bundler
set :bundle_without, %w{test production}.join(' ')
end

set :not_check_revision, true
#set :enable_locally_compile_assets, true

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
set :ssh_options, {
  #keys: %w(/home/rlisowski/.ssh/id_rsa),
  forward_agent: false,
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
