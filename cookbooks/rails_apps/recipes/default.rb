include_recipe "bundler"
include_recipe "deployer"
include_recipe "bluepill"
include_recipe "nginx"

%w(libsqlite3-dev nodejs).each do |p|
  package p
end

directory node[:rails_app][:config_root] do
  mode "0755"
end

node[:rails_applications].each do |rails_application, conf|
  directory "#{node[:rails_app][:config_root]}/#{rails_application}" do
    mode "0755"
  end
  conf[:environments].each do |env, env_conf|
    name = "#{rails_application}_#{env}"
    base_path = "#{node[:deployer][:home]}/#{name}"
    shared_path = "#{base_path}/shared"
    configuration = {
      :name => name,
      :env => env,
      :etc_path => "#{node[:rails_app][:config_root]}/#{rails_application}/#{env}",
      :current_path => "#{base_path}/current",
      :shared_path => "#{shared_path}",
      :shared_log_path => "#{shared_path}/log",
      :shared_sock_path => "#{shared_path}/sock",
      :shared_pids_path => "#{shared_path}/pids"
    }

    directory "#{base_path}" do
      owner node[:deployer][:user]
      group node[:deployer][:group]
      mode "0775"
    end
    [ :shared_path, :shared_log_path, :shared_sock_path, :shared_pids_path ].each do |path|
      directory "#{configuration[path]}" do
        owner node[:deployer][:user]
        group node[:deployer][:group]
        mode "0775"
      end
    end

    %w(releases releases/_init).each do |path|
      directory "#{base_path}/#{path}" do
        owner node[:deployer][:user]
        group node[:deployer][:group]
        mode "0775"
      end
    end
    link "#{configuration[:current_path]}" do
      to "#{base_path}/releases/_init"
      not_if do ::File.symlink?("#{configuration[:current_path]}") end
    end

    directory "#{configuration[:etc_path]}" do
      mode "0755"
    end
    %w(bluepill.rb unicorn.rb).each do |f|
      template "#{configuration[:etc_path]}/#{f}" do
        mode "0644"
        variables configuration
        notifies :restart, "service[#{name}]"
      end
    end

    template "/etc/init/#{name}.conf" do
      source "upstart.conf.erb"
      mode "0644"
      variables configuration
      notifies :restart, "service[#{name}]"
    end
    service name do
      provider Chef::Provider::Service::Upstart
      supports :status => true, :restart => true
      action [ :enable, :start ]
    end

    template "#{node[:nginx][:sites_available]}/#{name}" do
      source "nginx.conf.erb"
      mode "0644"
      variables configuration.merge({ :server_names => env_conf[:server_names] })
      notifies :reload, "service[nginx]"
    end
    link "#{node[:nginx][:sites_enabled]}/#{name}" do
      to "#{node[:nginx][:sites_available]}/#{name}"
      notifies :reload, "service[nginx]"
      not_if do ::File.symlink?("#{node[:nginx][:sites_enabled]}/#{name}") end
    end

  end
end unless node[:rails_applications].nil?
