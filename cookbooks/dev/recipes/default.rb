#
# Cookbook:: dev
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

execute 'install nvm' do
	command 'curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash'
	command 'source ~/.bashrc'
	command 'nvm install v11'
end

