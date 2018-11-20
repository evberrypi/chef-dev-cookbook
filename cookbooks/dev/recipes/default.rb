dev_password = data_bag_item('devbag', 'ev')

directory '/home/ubuntu/.ssh' do
  action :create
end

ssh_keygen '/home/ubuntu/.ssh/id_rsa' do
  action :create
  owner 'ubuntu'
  group 'dev'
  strength 4096
  type 'rsa'
  passphrase dev_password['password']
  comment 'ubuntu@localhost'
  secure_directory true
end
