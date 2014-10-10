require 'etc'

def localhost
  'localhost'
end

def local_user
  user = Etc.getlogin
  puts "====user: #{user}"
  user
end

on localhost do
  info 'on localhost ...'
end

on localhost do
  as local_user do
    within '/var/log' do
      puts capture(:whoami)
      puts capture(:pwd)
    end
  end
end
