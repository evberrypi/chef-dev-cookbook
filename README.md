# Chef Development Cookbook 

For running locally with Vagrant and Chef Hosted, or on AWS OpsWorks.
Part of a project to learn Chef to provision 3 nodes on AWS (Dev, Staging + Prod)

** For the front end Ionic/Angular app, please refer to [this repo](https://gitlab.com/evberrypi/ionicchef) **

For this project, I wanted to build a development, staging, and production server on AWS to learn Chef. In addition, I wanted to add a CI pipeline for code changes, have new versions built into Docker containers, and then have a Kubernetes Cluster run the production containers. All VMs are using Ubuntu 18.04, the applicaton is using Nodejs v11, and the database is Postgres. Additonal tools used include Habitat, Inspec, and Docker. 

### Getting setup
I use vagrant to set up an local workstation to write my recipes, and connect with the Amazon Opsworks Chef Automate Server, as well as any EC2 instances that we will spin up. You do not need to use OpsWorks, and can use a service called (Chef Hosted)[https://manage.chef.io/signup], which is a managed Chef server and provides connection to the first 5 nodes free of charge. Alternatively, you can also the open source version of Chef Automate on your own server [link](https://downloads.chef.io/).

Here is the [link](https://gitlab.com/snippets/1777876) to my Vagrantfile, it is modified slightly from [Chefs Version](https://automate.chef.io/docs/quickstart/) to include the latest version of Ubuntu.

to follow along:
```
wget -O Vagrantfilehttps://gitlab.com/snippets/1777876
vagrant up
vagrant ssh
```
## AWS:
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

### Using Hosted Chef
If instead of running on AWS Open Stack, you chose to setup on Chef Hosted, do the following:
```
#create a chef project directory:
vagrant@vagrant:~$ mkdir chefdir/.chef
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

We can provision a new node on an AWS EC2 using the `knife` command. Export your Aws `Access Key ID` and `Secret Access Key` variables to your shell (or append them to your .bash_profile to make the changes permanent)
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
knife ec2 server create -r 'role[admin]' --aws-access-key-id $AWS_ACCESS_KEY_ID --aws-secret-access-key $AWS_SECRET_ACCESS_KEY --ssh-key eeceetoo  -ssh-gateway-identity ~/eeceetoo.pem --ssh-user ubuntu
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

Since we will be using a nodejs app, let's fetch the cookbook for nodejs within the `cookbooks` directory:
```
git clone https://github.com/redguide/nodejs.git
```
edit the recipes/default.rb file to include npm:
```
include_recipe 'nodejs::npm'
```
Now upload the recipe to the server
```
knife upload nodejs
```

Because our development node will clone down our repository, and should be able to push do our development branch, we will need to get our SSH keys onto our system, and can add them in what is called a `data bag` on the Chef Server, so our cookbooks have access to these variables. Data bags are important for sensitive secrets and config variables that shouldn't be hard-coded in your application. We can create one by running:
```
knife data bag create devbag
```
For this example dev server, however, we will simply make sure that the correct SSH keys are already added on our VM, and that we have ran an initial `git config --global` to set our dev user credentials. In production, the most recommended cookbook for using a data bag is the [user-ssh-keys-cookbook](https://github.com/pmsipilot/user-ssh-keys-cookbook).

### Running the development cookbook
Generate a new cookbook called dev, `knife generate cookbook dev` and edit the /recipes/default.rb
```

```
The following command will run `chef-client`, updating the new node and installing the new recipe and package:
```
knife ssh "name:dev" "sudo chef-client" -x ubuntu -i ~/awskey.pem
```
You should see a bunch of output showing that the recipe ran successfully and can verify by ssh-ing into the EC2 and typing `node`



And that's it for our development node, it is set up with npm and nodejs, and clones down the correct repo.
Your devs can run npm run dev to view hot uploads, and code pushes will be reflected in Gitlab.

* * *

## Todo
- [ ] Have Chef Provision Staging Server
- [ ] Adjust .gitlab-ci.yml to not fail on buld
- [ ] Have final Dev node run on AWS Kubernetes
