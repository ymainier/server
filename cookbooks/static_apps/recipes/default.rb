include_recipe "bundler"
include_recipe "deployer"
include_recipe "nginx"

node[:static_applications].each do |static_application, conf|
  conf[:environments].each do |env, env_conf|
    name = "#{static_application}_#{env}"
    base_path = "#{node[:deployer][:home]}/#{name}"
    shared_path = "#{base_path}/shared"
    configuration = {
      :name => name,
      :env => env,
      :current_path => "#{base_path}/current",
      :shared_path => "#{shared_path}",
      :shared_log_path => "#{shared_path}/log",
    }

    directory "#{base_path}" do
      owner node[:deployer][:user]
      group node[:deployer][:group]
      mode "0775"
    end
    [ :shared_path, :shared_log_path ].each do |path|
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
      notifies :reload, "service[nginx]"
      not_if do ::File.symlink?("#{configuration[:current_path]}") end
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
end unless node[:static_applications].nil?

