package "nginx"

service "nginx" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

execute "allow http connection" do
  not_if "ufw status | grep 80"
  command "ufw allow 80"
end

