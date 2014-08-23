itop-utilities
==============

Utilities scripts for itop, an open source cmdb. 

Empowers CMDB by connectincg to other system like Ansible.

Script FromITOPtoAnsible.sh
==

 This script pulls info from an ITOP cmdb to generate  a yaml hosts list to be used as a Dynamic Inventory Source for ansible commands.
 This is very useful to perform operations on groups of hosts, according to your physical, logical or network infrastructure, or according your services, as it is defined on your cmdb. 
 
 For example, you can send commands to all machines of a given rack, or those plugged to a specific network device, or those having related open tickets. You have to define a set of hosts by using an OQL select statement.
 
 
Scipt parameters 
=====
 
 
 Passed as enviroment variable 
  * OQL = Sentence in OQL 
  * FIELD = (optional) name of the field to be used as hostname 
 
Script usage example 
====


 Perform a ping against all VM's belonging to a given hypervisor named prod-epg-esxi-04.hi.inet 
 
``` bash
export OQL="SELECT VirtualMachine WHERE virtualhost_name = 'prod-epg-esxi-04.hi.inet' "  
ansible all -i FromITOPtoAnsible.sh -m shell -m "ping" 
```




 
 
