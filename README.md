## Vagrant environement for puppet

Configure a puppet development/demo environment with the following components:
- puppetmaster, puppetdb and puppetboard (either on a single VM or multiple ones)
- additional nodes to test agents
- this repository consists of a Vagrantfile defining several possible hosts and bootstrap scripts to install master and agents
- all the configuration is done via puppet using a control repo synchronized on the master via r10k: https://github.com/lbernail/puppet-r10k

### Bootstrap the puppetmaster in standalone mode
This installation provides a master with puppetdb and puppetboard on single VM. To use this, your master node needs to have the role **role::master_standalone**. See https://github.com/lbernail/puppet-r10k/blob/production/manifests/nodes.pp for role assignment and https://github.com/lbernail/puppet-r10k/tree/production/site/role/manifests for role list. To change the master role (standalone or not) you will have to fork the puppet-r10k repo, modify theses files and update the r10k configuration in the bootstrap script to use your repo.

* Install virtualbox and vagrant
* Clone vagrant files
```
git clone https://github.com/lbernail/vagrant-puppet.git
```
* Go into puppet env, create puppet master and configure it (default box: boxcutter/ubuntu1604)
```
cd vagrant-puppet
vagrant up puppetmaster
```  
*Details about virtual machines are in the Vagrantfile (private network for puppet, port redirection for puppetboard, hosts file)*
* When the vm boots for the first time, vagrant provisioning kicks in using **bootstrap.sh**.
Main steps:
    - Modifying apt sources to rely on AWS Europe
    - Configuring puppetlabs repo
    - Updading apt cache
    - Installing puppet, rubygems and git
    - Install hiera-eyaml and copy sample keys (THESE ARE ONLY HERE TO HAVE A WORKING ENVIRONMENT. CHANGE THEM)
    - Creating hiera.yaml (simple conf, see bootstrap.sh content)
    - Creating r10k.yaml (configure git repo with sitemodules, manifests and Puppetfile to download forge modules
    - Installing r10k gem
    - Deploying with r10k (download all puppet conf from git / forge)
    - Performing first puppet run (puppetmaster role configures puppet master, puppetdb and puppetboard)

After a few minutes everything should ready and you should be able to access puppetboard from host: http://localhost:5000


### Check master configuration
1. Connect to master
```
vagrant ssh puppetmaster
```
2. First agent run on the master (first run was an apply run)
```
sudo /opt/puppetlabs/puppet/bin/puppet agent -t
```  
*This run will sync plugins and should do nothing (maybe a few changes because some modules change a few things on the second run)*
3. Puppetboard will show the new run: http://localhost:5000/


### Bootstrap the puppetmaster with separate puppetdb and Puppetboard
Setting up the master is similar to standalone but the node needs the role **role::master** and you need a node with role **role::puppetdb** and optionnally one with role **role::puppetreports**. The assignment of the VM created by vagrant and their roles can be found at https://github.com/lbernail/puppet-r10k/blob/production/manifests/nodes.pp
```
node 'puppetmaster' {
  include role::master
}
node 'puppetdb' {
  include role::puppetdb
}
node 'puppetreports' {
  include role::puppetreports
}
```
1. Create the puppetmaster: ```vagrant up puppetmaster```
2. Create the puppetdb: ```vagrant up puppetdb```. This will install the agent and perform a first puppet run against the master. It will trigger warnings because the master is configured to use puppetdb (see the master profile) but this role is not available *yet*. You will not need to sign the node certificates because autosigned is configured on the master for puppetdb and puppetreports (autosign.conf is created by the master profile using data for hiera: https://github.com/lbernail/puppet-r10k/blob/production/hieradata/nodes/puppetmaster.vm.local.yaml)
3. Create the puppetreports node  ```vagrant up puppetreports```
4. You can now access puppetboard at http://localhost:5001


### Add client virtual machines
websrv and dbsrv are configured in Vagrantfile (very easy to add new ones): same private network setup, hosts file configuration, no puppet
1. Create VM: ``` vagrant up websrv```. This will install the agent and perform a first run which will fail because websrv is not configured for autosigning.
2. Connect to the master and list / sign
```
vagrant ssh puppetmaster
sudo /opt/puppetlabs/puppet/bin/puppet cert list [--all]
sudo /opt/puppetlabs/puppet/bin/puppet cert sign websrv.vm.local
```
3. Connect to the VM and rerun puppet
```
vagrant ssh websrv
sudo /opt/puppetlabs/puppet/bin/puppet agent -t
```  
*This will only give a notice: Default class for unknown node (from default node in site.pp).  
Puppetboard now shows this additional host*
6. Change site.pp, add profile to websrv node,....

### Support for hiera-eyaml
This setup includes hiera-eyaml

- During the bootstrap the hiera-eyaml gem is installed and the hiera.yaml is configured to support the eyaml backend
- To create your own keys, install the hiera-eyaml gem and simply run ```eyaml createkeys```
- Keys are copied to /var/lib/puppet/secure/keys
- The hieradata on github refered to in the r10k configuration contains an encrypted content
- To create an eyaml encrypted string use ```eyaml encrypt -s "Message"```
- Then simply add the output to a hiera yaml file
```
key: >
   ENC[PKCS7,...]
```
- The base profile contains a notice that will show the decrypted content in all runs


### Snapshot fresh install
If you want to be able to go back to a clean puppetmaster, db and or reports (fresh from install, without having to do the full provisioning)
1. Install snaphost plugin
```
vagrant plugin install vagrant-vbox-snapshot
```
2. Snapshot VM:
```
vagrant snapshot take puppetmaster freshinstall
```
3. After this you can go back to the snaphost if needed:
```
vagrant snapshot go puppetmaster freshinstall
```
You can find more information here: https://github.com/dergachev/vagrant-vbox-snapshot


### Alternative separate install for centos7 support

just add the env var `VAGRANT_VAGRANTFILE=Vagrantfile.centos` before you run commands, it will use the `Vagrantfile.centos` Vagrantfile, `boostrap_centos.sh`, `install_agent_centos.sh` bootstrap files.

```
VAGRANT_VAGRANTFILE=Vagrantfile.centos vagrant up puppetmaster
VAGRANT_VAGRANTFILE=Vagrantfile.centos vagrant up puppetdb
VAGRANT_VAGRANTFILE=Vagrantfile.centos vagrant up puppetreports
```
