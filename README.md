# ansible-percona-for-mysql-install-standalone
Ansible routines to deploy Standalone Percona for MySQL installation on CentOS / Red Hat Linux distros.

In this file, I will present and demonstrate how to install MySQL in an automated and easy way.

For this, I will be using the scenario described down below:
```
1 Linux server for ansible
1 Linux server for MySQL (the one that we will install MySQL using Ansible)
```

First of all, we have to prepare our Linux environment to use Ansible

Please have a look below how to install Ansible on CentOS/Red Hat:
```
yum install ansible -y
```
Well now that we have Ansible installed already, we need to install git to clone our git repository on the Linux server, see below how to install it on CentOS/Red Hat:
```
yum install git -y
```

Copying the script packages using git:
```
cd /root
git clone https://github.com/emersongaudencio/ansible-percona-for-mysql-install-standalone.git
```
Alright then after we have installed Ansible and git and clone the git repository. We have to generate ssh heys to share between the Ansible control machine and the database machines. Let see how to do that down below.

To generate the keys, keep in mind that is mandatory to generate the keys inside of the directory who was copied from the git repository, see instructions below:
```
cd /root/ansible-percona-for-mysql-install-standalone/ansible
ssh-keygen -f ansible
```
After that you have had generated the keys to copy the keys to the database machines, see instructions below:
```
ssh-copy-id -i ansible.pub 172.16.122.137
```

Please edit the file called hosts inside of the ansible git directory :
```
vi hosts
```
Please add the hosts that you want to install your database and save the hosts file, see an example below:

```
# This is the default ansible 'hosts' file.
#

## [dbservers]
##
## db01.intranet.mydomain.net
## db02.intranet.mydomain.net
## 10.25.1.56
## 10.25.1.57

[dbservers]
dblocalhost ansible_connection=local
dbmysql56 ansible_ssh_host=172.16.122.136
dbmysql57 ansible_ssh_host=172.16.122.137
dbmysql80 ansible_ssh_host=172.16.122.138
```

For testing if it is all working properly, run the command below :
```
ansible -m ping dbmysql57 -v
```

Alright finally we can install our MySQL 5.7 using Ansible as we planned to, run the command below:
```
sh run_mysql_install.sh dbmysql57 57
```
### Parameters specification:
#### run_mysql_install.sh
Parameter    | Value         | Mandatory     | Order         | Accepted values
------------ | ------------- | ------------- | ------------- | ---------------
host | dbmysql57 | Yes | 1 | hosts who are placed inside of the hosts file
db mysql version | 57 | Yes | 2 | 56, 57, 80

PS: Just remember that you can do a single installation at the time or a group installation you inform the name of the group in the hosts' files instead of the host itself.

The versions supported for this script are these between the round brackets (56, 57, 80).
