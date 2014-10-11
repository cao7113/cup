#Note: run me by bin: rssh

run_locally do
  log '==############## Hi on local ...'
end

on 'localhost' do |host|
  execute :echo, 'hi from localhost via ssh...'

  ## Execute and raise an error if something goes wrong
  #This will raise `SSHKit::Command:Failed` with the `#message` "Example Message!" which will cause the command to abort.
  #execute(:echo, '"这里是出错信息!" 1>&2; false')
end

#run_locally do
  #as 'www-data' do
    #within '/var/log' do
      #puts capture(:whoami)
      #puts capture(:pwd)
    #end
  #end
#end

run_locally do
  log '==############## All running end!'
end
