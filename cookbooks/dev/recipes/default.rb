#
# Cookbook:: dev
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

execute 'npm_install' do
  command 'npm install'
  user 'nodejs'
  cwd '/opt/nodejs/myapp/'
  action :nothing
end
