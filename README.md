itop-utilities
==============

Utilities scripts for itop, an open source cmdb. 

Empowers CMDB by connectincg to other system like Ansible.

Script FromITOPtoAnsible.sh
==

 This script pulls info from an ITOP cmdb to generate  a yaml hosts list to be used as a Dynamic Inventory Source for ansible commands.
 This is very useful to perform operations on groups of hosts, according to your physical, logical or network infrastructure, or according your services, as it is defined on your cmdb. 
 
 For example, you can send commands to all machines of a given rack, or those plugged to a specific network device, or those having related open tickets. You have to define a set of hosts by using an OQL select statement.
 
Installation
=====
 As a prerequisite, you need an iTop instance, and an Ansible instance too, in the same or in different servers.
 Just copy the script to your ansible machine, in /etc/ansible, and made it executable.

``` bash 
 cd /etc/ansible
 wget --no-check-certificate https://github.com/jaimevalero78/itop-utilities/raw/master/FromITOPtoAnsible.sh  
 chmod +x /etc/ansible/FromITOPtoAnsible.sh
``` 

 Also, you have to change the credentials for the itop instance in the script. The parameters you should change are:
``` bash  
# Parameters: Change this according to your itop credentials 

MY_USER=replace_for_your_itop_user
MY_PASS=replace_for_your_itop_password
ITOP_SERVER=replace_for_your_itop_server
INSTALLATION_DIRECTORY=itop-itsm
HTTPS=Y

``` 

Script parameters 
=====
 
 
 Passed as enviroment variable 
  * OQL = Sentence in OQL 
  * FIELD = (optional) name of the field to be used as hostname 
 
Script usage example 
====


 Perform a ping against all HP Server against the itop demo instance. http://goo.gl/FrOQdQ 
 
``` bash
cd /etc/ansible

export OQL="SELECT Server WHERE brand_name = 'HP'"
 
ansible all -i FromITOPtoAnsible.sh -m shell -m "ping" 

# The above command would try to access each of the server list : { "hosts" : [ "Server1" , "Server3" , "Server4" , "SRV1" , "SRV1" , "Web" ] }
# and try to login against it. 
# It will fail, of course. You have to configure the script to query your own itop and ansible instances!


```




 
 
