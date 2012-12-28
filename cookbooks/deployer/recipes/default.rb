include_recipe "admin_users"

user node[:deployer][:user] do
  shell "/bin/bash"
  home node[:deployer][:home]
  supports :manage_home => true
  action [:create]
end

group "admin" do
  action :modify
  members node[:deployer][:user]
  append true
end

directory node[:deployer][:home] do
  owner node[:deployer][:user]
  group node[:deployer][:group]
  mode "6755"
end

keys = {}

node[:administrative_users].each do |name, conf|
  conf[:keys].each do |k, v|
    keys[name + k] = v
  end
end unless node[:administrative_users].nil?

directory "#{node[:deployer][:home]}/.ssh" do
  owner node[:deployer][:user]
  mode "0700"
end

execute "generate ssh keys for #{node[:deployer][:user]}" do
  user node[:deployer][:user]
  creates "#{node[:deployer][:home]}/.ssh/id_rsa.pub"
  command "ssh-keygen -t rsa -q -f #{node[:deployer][:home]}/.ssh/id_rsa -P \"\""
end

template "#{node[:deployer][:home]}/.ssh/authorized_keys" do
  cookbook "admin_users"
  owner node[:deployer][:user]
  variables :keys => keys
  mode 0600
end

execute "Add local keys to authorized keys" do
  user node[:deployer][:user]
  not_if " grep \"deployer local\" #{node[:deployer][:home]}/.ssh/authorized_keys"
  command <<-CMD
echo "# deployer local" >> #{node[:deployer][:home]}/.ssh/authorized_keys
cat #{node[:deployer][:home]}/.ssh/id_rsa.pub >> #{node[:deployer][:home]}/.ssh/authorized_keys
CMD
end

file "#{node[:deployer][:home]}/.ssh/known_hosts" do
  owner node[:deployer][:user]
  mode "0644"
end

ipv4s = []
node['network']['interfaces'].each do |_, iface|
  iface[:addresses].each do |addresse, conf|
    ipv4s << addresse if conf[:family] == 'inet'
  end unless iface[:addresses].nil?
end
hostid = "#{node[:fqdn]},#{ipv4s.join(',')}"

execute "Add current node to the deployer known hosts" do
  user node[:deployer][:user]
  not_if "grep \"#{hostid}\" #{node[:deployer][:home]}/.ssh/know_hosts"
  command "ssh-keyscan #{hostid} > #{node[:deployer][:home]}/.ssh/known_hosts"
end

 
#file "#{node[:deployer][:home]}/.ssh/know_hosts" do
  #owner node[:deployer][:user]
  #mode "0644"
#end

