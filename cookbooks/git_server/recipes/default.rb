include_recipe "git"
include_recipe "admin_users"

user node[:git_server][:user] do
  system true
  shell "/bin/false"
  home node[:git_server][:root]
  supports :manage_home => true
  action [:create]
end

# install thor and some script to help create git repositories
gem_package "thor"

# each admin user is in the git group
node[:administrative_users].each do |name, conf|
  group node[:git_server][:user] do
    action :modify
    members name
    append true
  end

  base_bin = "#{node[:admin_users][:base_home]}/#{name}/bin"

  directory base_bin do
    owner name
    group name
    mode "0755"
  end

  cookbook_file "#{base_bin}/repo" do
    owner name
    group name
    mode "0755"
  end
  template "#{base_bin}/repo.thor" do
    owner name
    group name
    mode "0644"
    variables({ :name => name })
  end
end unless node[:administrative_users].nil?
