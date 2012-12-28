package "build-essential"
gem_package "ruby-shadow"

group "admin" do
  action :create
  system true
  members( node[:from_vagrant].nil? ? nil : [ "vagrant" ] )
end

node[:administrative_users].each do |name, conf|

  home_dir = "#{node[:admin_users][:base_home]}/#{name}"

  user name do
    shell "/bin/bash"
    password conf[:password]
    home home_dir
    supports :manage_home => true
    action [:create]
  end

  directory home_dir do
    owner name
    mode 0700
  end

  directory "#{home_dir}/.ssh" do
    owner name
    mode 0700
  end

  template "#{home_dir}/.ssh/authorized_keys" do
    owner name
    variables :keys => conf[:keys]
    mode 0600
  end

  group "admin" do
    action :modify
    members name
    append true
  end
end
