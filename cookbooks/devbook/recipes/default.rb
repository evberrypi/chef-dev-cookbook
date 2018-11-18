#
# Cookbook:: devbook
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
include_recipe 'nodejs::npm'
user 'ubuntu'
git "/home/ubuntu" do 
    repository "git@gitlab.com:evberrypi/ionicchef.git"
    action :checkout
    reference "master"
    user "ubuntu"
end


#npm_package 'ionic -g' do
#    path '/home/ubuntu/ionicchef'
#end
# make sure that the new repo is ready to go!
#Nodejs cookbook works well, but not for the one global package we want to use
execute 'npm install -g ionic'