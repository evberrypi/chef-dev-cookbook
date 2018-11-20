## Using Chef to Deploy A Simple Ionic/Angular Todo App on AWS 
This is code for the Todo app is [here](https://gitlab.com/evberrypi/ionaws). It is a simple javascript web/hybrid mobile app using Ionic/Angular which connects with AWS Cogito for User managment, S3 for static file hosting, and DynamoDB (Serverless NoSQL) for the apps backend.

Follow along with this guide to run it.
- The final versions of the cookbooks used in this project can be found [here](gitlab.com/evberrypi/chef-dev-cookbook)  


### Getting setup
I use vagrant to set up an local workstation to write my recipes, and connect with the Amazon Opsworks Chef Automate Server, as well as any EC2 instances that we will spin up. You do not need to use OpsWorks, and can use a service called (Chef Hosted)[https://manage.chef.io/signup], which is a managed Chef server and provides connection to the first 5 nodes free of charge. Alternatively, you can also the open source version of Chef Automate on your own server [link](https://downloads.chef.io/).

Here is the [link](https://gitlab.com/snippets/1777876) to my Vagrantfile, it is modified slightly from [Chefs Version](https://automate.chef.io/docs/quickstart/) to include the latest version of Ubuntu.

to follow along:
```
wget -O Vagrantfilehttps://gitlab.com/snippets/1777876
vagrant up
vagrant ssh
```

# Launching your Chef Server
After your workstation is set up, you will need a Chef Server, which can run locally or on a hosted server. In this guide I'll cover launching on AWS Opsworks and Managed Chef.

## Launch Chef Automate Server on AWS Opsworks:
First create a [Chef Automate Server for AWS](https://console.aws.amazon.com/opsworks/cm/home?owc=chefautomate&region=us-east-1#/chef/) on  AWS OpsWorks
It will launch an Amazon t2.large.
While this runs for 20 minutes, you can download the credentials for the Chef Automate panel and a chef starter kit for cookbooks and provisioning new nodes. The first thing to do is install the [ChefDK (development kit)](https://downloads.chef.io/chefdk). Copy the url for your particular distribution

```
# unzip the AWS Opsworks starter kit (change 'your-starterkit-name')
vagrant@chef-automate:~$ unzip {your-starterkit-name}
vagrant@chef-automate:~$ mv {your-starterkit-name} chefdir
vagrant@chef-automate:~$ cd chefdir
vagrant@chef-automate/chefdir:~$ wget -O chefdk.deb https://packages.chef.io/files/stable/chefdk/3.4.38/ubuntu/18.04/chefdk_3.4.38-1_amd64.deb
vagrant@chef-automate/chefdir:~$ sudo dpkg -I chefdk.deb
vagrant@chef-automate/chefdir:~$ rm chefdk.deb
```

You now have ChefDk installed and access to the `Knife` command.
```
# check to validate the SSL certificate to ensure you can issue commands to the Chef Server.
knife ssl check
```
When your OpsWorks instance is finally ready, you can login with the credentials downloaded from the OpsWorks panel named `{your-server-name}_credentials.csv` 

## Use Chef's Hosted Server
If instead of running on AWS Open Stack, you chose to setup on Chef Hosted, do the following:
```
#create a chef project directory:

vagrant@vagrant:~$ mkdir chefdir/
vagrant@vagrant:~$ mkdir chefdir/.chef

#install the Chef Development Kit (ChefDK)
vagrant@vagrant/chefdir:~$ wget -O chefdk.deb https://packages.chef.io/files/stable/chefdk/3.4.38/ubuntu/18.04/chefdk_3.4.38-1_amd64.deb
vagrant@vagrant/chefdir:~$ sudo dpkg -I chefdk.deb
vagrant@vagrant/chefdir:~$ rm chefdk.deb

#make a cookbooks directory
vagrant@vagrant:~$ mkdir chefdir/cookbooks
```
Login to your Hosted Chef panel and select `Administration` then select `Users` from the left side of the screen. In this dropdown, select `Generate Knife Config`.
Download your `knife.rb` file and place it in the newly created `.chef` directory.
On the left side on the menu select `Reset Key`, confirm key reset and download the `.pem` file and place it in the `.chef` directory.

Now run `knife ssl check` to verify that everything has worked. The output should resemble the following:

```
Connecting to host api.chef.io:443
Successfully verified certificates from `api.chef.io'
```
If you are going to be connecting any existing non-AWS servers to the Hosted Chef instance, while still on the `Users` tab, you will see the public key for your user account. You will need to add it to your `.ssh/authorized_keys` file on your target host/existing server before you can bootstrap your node to be able to connect to the Chef Server. You can skip down to the instructions for **Connecting an Existing Server/EC2**
* * *


# Creating a development node
For our development node, we want our server automatically provisioned to run a development sandbox but we will start by connecting to an existing AWS server.

We can provision a new node on an AWS EC2 using the `knife` command. Export your Aws `Access Key ID` and `Secret Access Key` variables to your shell (alternatively, append them to your .bash_profile to make the changes permanent)
```
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export EC2_AVAILABILITY_ZONE=us-east-1a
export EC2_REGION=us-east-1
```

Now add the following to your .knife.rb
```
knife[:aws_access_key_id] = ENV['AWS_ACCESS_KEY_ID']
knife[:aws_secret_access_key] = ENV['AWS_SECRET_ACCESS_KEY']
knife[:availability_zone] = "#{ENV['EC2_AVAILABILITY_ZONE']}"
knife[:image] = "ami-0ac019f4fcb7cb7e6"
#knife[:flavor] = "m1.medium"
knife[:flavor] = "t1.micro"
knife[:chef_mode] = "solo"
#knife[:ssh_key] = "#{ENV['SSH_KEY']}"
knife[:region] = "#{ENV['EC2_REGION']}"

```
### To Create a New Connected Node on an Amazon EC2
Create a new ec2, substituting `amazonpem.pem` and `amazonpem` with your respective .pemfile and name found on the [Access and Identity Managment console](https://console.aws.amazon.com/iam/home?region=global#/users):
```
knife ec2 server create -r 'role[dev]' --aws-access-key-id $AWS_ACCESS_KEY_ID --aws-secret-access-key $AWS_SECRET_ACCESS_KEY --ssh-key eeceetoo  -ssh-gateway-identity ~/eeceetoo.pem --ssh-user ubuntu
```
If, after provisioning, there was an error (usually with SSH timeout during creation), you can run the `knife bootstrap` command below to enable chef-client on your new instance.

### Connecting an Existing Server /EC2
This following command will bootstrap an existing server to the Chef Automate Server and add the Chef Development Kit (ChefDK):
```
knife bootstrap ec2-18-205-3-35.compute-1.amazonaws.com --ssh-user ubuntu --sudo --identity-file ~/awskey.pem --node-name dev
```
Log into the Chef Workstation to verify that everything works. You should see that there is a newly connected node and cookbooks uploaded to your server. 
![Screenshot from 2018-11-15 01-23-54.png](:/71d593449eff43009bde927648a35f63)

* * *

If you ran the `knife ec2 connect` command above, you can see your new EC2 instance details on the [EC2 instance page](https://console.aws.amazon.com/ec2/v2/home?region=global#Instances:sort=instanceId).

## Put Secrets in a Data Bag
Because our development node will clone down our repository, and should be able to push do our development branch, we will need SSH keys on our VM and a copy of the public Key on our Server. Can use what is called a `data bag` on the Chef Server, so our cookbooks have access to secrets like keys and passwords without needing to hard-code the values. Depending on your needs you may not want to have Chef Server store SSH Keys. In this example, I am going to have Chef generate my ssh keys for me, but fetch a password from a data bag to demonstrate both.
```python
# create the devbag
knife data bag create devbag

# Now generate a password on the commandline
:~$ openssl passwd -1 -salt yoursalt yoursecretpassword
# will output the following, copy this down
$1$yoursalt$FMPL17Ff0iki1kkpDWluQ1
```
create a file called devbag.json
and add in the following:
```json
{
    "id": "dev",
    "password": "$1$yoursalt$FMPL17Ff0iki1kkpDWluQ1"
}
```
To add this data to the data bag run:
```
knife data bag from file devbag ./devbag.json
```
You now have access to this password in your cookbooks!

### Running the development cookbook
`cd` into the `cookbooks` directory and generate a new cookbook called dev by running `knife generate cookbook dev` and paste in the following into /recipes/default.rb
```
#import the data bag
dev_password = data_bag_item('devbag', 'dev')

group 'dev' do
  action :create
end


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
```
The recipe above will generate an SSH-Key, but depends on a public cookbook which is not yet on our server. First, from within the `cookbooks/dev` directory,add the following line to the bottom of your `Berksfile`:
```
cookbook 'ssh_keygen', '~> 1.1.0'
```
Now edit `cookbooks/dev/metadata.rb` and add the following to the bottom of the file:
```
depends 'ssh_keygen'
```
You can now install this cookbook to your server by running:
```
berks install
berks upload
```


### Run Lists
Now that our cookbooks are on the server, we need to get them on our nodes. The Chef Server and Workstation can keep track of what cookbooks are needed on a given node. Run `knife node edit dev`. We will be adding `recipe[dev]` to the `run_list` section like so:
```
{
  "name": "dev",
  "chef_environment": "_default",
  "normal": {
    "tags": [

    ]
  },
  "policy_name": null,
  "policy_group": null,
  "run_list": [
  "recipe[dev]"
]

}

```
Now the chef server knows that the `dev` cookbook is part of the development nodes runtime configuration. 

### Run Chef Client

Now that this is on the server, we can run `chef-client` to update the new node, install the new recipe and generate our SSH key:
```
knife ssh "name:dev" "sudo chef-client" -x ubuntu -i ~/awskey.pem
```
You should see a bunch of output showing that the recipe ran successfully and can grab the newly minted ssh public key from the output:


![Screenshot from 2018-11-19 17-09-44.png](:/fcbd77b4f6b44074bdda28d7b0a7ee4b)

Copy this key and add it to Gitlab or wherever you forked the [Ionic AWS Todo App](gitlab.com/evberrypi/ionaws) to.

On your workstation (not the new node), clone down your forked version of the Todo App. Before we can deploy it, we will need to generate one additional cookbook that will pull this repo down from Gitlab and install nodejs using nvm (to avoid permissions issueswhen adding global packages).

Let's create one additional cookbook `ionic`.
```
chef generate cookbook ionic
```
`cd` into the `cookbooks/ionic` folder and add the following to your `Berksfile`:
```
cookbook 'nvm', '~> 0.1.7'
```
Update `metadata.rb` to include these packages in this cookbook:
```
depends nvm
```
Finally, add the following to your `recipes/default.rb`
```
include_recipe 'nvm'
dev_password = data_bag_item('devbag', 'dev')
# install node.js v11
nvm_install 'v11.2.0'  do
  from_source false
  alias_as_default true
  action :create
  user 'ubuntu'
end

user 'ubuntu'
git "home/ubuntu/ionicchef" do
  repository "git@gitlab.com:evberrypi/ionicaws.git"
  action :checkout
  reference "master"
  passphrase dev_password
  user "ubuntu"
end
```
Run `berks install && berks upload` to get the `ionic` cookbook onto the server. From there run `knife node edit dev` and add `recipe[ionic]` to your run-list, like we did with the first cookbook.
To install node and clone the repo, run the following from your workstation:
```
knife ssh "name:dev" "sudo chef-client" -x ubuntu -i ~/awskey.pem
```
# Run the app

Congrats! You have now created two chef recipes that clone down a simple todo list app.
To run it, ssh into your machine. You will need to run the following:
```
npm i -g ionic // you can install global nodejs packages without sudo access
npm install -g awsmobile-cli
cd ionaws
ionic serve
```

Running `ionic serve` will launch the app with livereloading at <ec2-address>:8000, and will also provide an address for developers to test the app live on their phone if using the Ionic Devapp for [android](https://play.google.com/store/apps/details?id=io.ionic.devapp&hl=en) or [ios](https://itunes.apple.com/us/app/ionic-devapp/id1233447133)

You are now ready to connect the Ionic App to the steps in the [README](https://gitlab.com/evberrypi/ionicaws) to connect the app to AWS DynamoDB for App storage, S3 for static web hosting, and Cognito for User Managment on the Development EC2.


## Production?
With this setup, it is easy to use Chef to launch a Staging/Prod server with a similar setup. We simply launch a new node, add one additional cookbook, create a role called prod, then configure the app as described in the [README](https://gitlab.com/evberrypi/ionicaws). We mainly do this to give the Development app and the Production app different DynamoDB instances.

```
# Have Chef spin up a new node:
knife ec2 server create --role[prod] --aws-access-key-id $AWS_ACCESS_KEY_ID --aws-secret-access-key $AWS_SECRET_ACCESS_KEY --ssh-key eeceetoo  -ssh-gateway-identity ~/eeceetoo.pem --ssh-user ubuntu

# edit the prod role
knife role edit prod
```
It will look similar to the `dev` role created earlier, but with [Chef Habitat](https://www.habitat.sh) added, to easily dockerize the app director -- in the event we want to run the app on Kubernetes.
```
# add these to your run list for `prod`
  "recipe[prod]",
  "recipe[ionic]"
```
Create the `prod` cookbook:
```
chef generate cookbooks/prod
```
Add to the `prod/Berksfile`
```
  "recipe[prod]",
  "recipe[ionic]"
```
Add to the `prod/metadata.rb`
```
depends 'ssh_keygen'
depends 'habitat'
```
Add to the `prod/recipes/default.rb` 
```
prod_password = data_bag_item('devbag', 'ev')

directory '/home/ubuntu/.ssh' do
  action :create
end

ssh_keygen '/home/ubuntu/.ssh/id_rsa' do
  action :create
  owner 'ubuntu'
  group 'dev'
  strength 4096
  type 'rsa'
  passphrase prod_password['password']
  comment 'ubuntu@localhost'
  secure_directory true
end
hab_install 'install habitat' do
  create_user false
end
```
To upload it to your server run:
```
knife ssh "name:prod" "sudo chef-client" -x ubuntu -i ~/awskey.pem
```
It will fail the first time, since the SSH key generated has not yet been added to Gitlab, but after adding this new key, run the above `knife ssh` command again and it should work.

You now have a second node. SSH into it and complete the steps in the README, and it will be configured as a second app in the Mobile Hub, allowing you to make changes in the Dev Env, with a test DynamoDb database, and pull down your changes to your prod/staging server after they have been approved. The prod version with its production database will be for final users to keep their todos in safely and securely. We have installed [habitat](habitat.sh).

#### To build into a docker container:
On the new Prod/Staging server, `cd` into the app directory and type `hab cli setup`, select `no` for on premesis, and `yes` to setting the origin.  
Habitat requires a plan.sh file to build the app to a Docker Image. To generate this for a node app type `hab plan init -s node`. This will create a clean environment for a docker build. Enter into this environment by typing `hab studio enter`.
Finally build this into a docker image by typing `build` from within the Habitat studio.
Congrats, you now have a containerized production web app. Folow [these instructions](https://kinvolk.io/blog/2017/12/automated-build-to-kubernetes-with-habitat-builder/) to have it auto launched to Kubernetes.

## Screenshots


![Screenshot from 2018-11-19 21-10-56.png](:/2b7ed2d372154255a4378d48434a5c48)
Identity Managment powered by Cognito



![Screenshot from 2018-11-19 21-11-50.png](:/22ff1ad80edc4ab8a87f603097af00bd)

Email Verification


![Screenshot from 2018-11-18 17-18-53.png](:/49af89c2ca274e238a224caddf47736b)
Adding Services in Mobile Hub



![Screenshot from 2018-11-18 18-04-36.png](:/810b616bd0924739afe2094be2e77ce9)

And finally, we can add a todo to our app! 




