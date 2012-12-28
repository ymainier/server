package 'ufw'

execute "allow ssh connection" do
  not_if "ufw status | grep 22"
  command "ufw allow 22"
end

execute "enable firewall" do
  not_if "ufw status | grep 'Status: active'"
  command "echo y|sudo ufw enable"
end
