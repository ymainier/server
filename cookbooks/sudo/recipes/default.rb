# From https://github.com/opscode-cookbooks/sudo/blob/master/recipes/default.rb
package 'sudo' do
  action :install
end

cookbook_file '/etc/sudoers' do
	source 'sudoers'
	mode '0440'
	owner 'root'
	group 'root'
end

