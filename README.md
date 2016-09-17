## Vagrant environement for puppet

Configure a puppet development/demo environment with the following components:
- puppetmaster vm with puppetdb and puppetboard
- additional nodes to test agents

### Bootstrap the puppetmaster

* Install virtualbox and vagrant
* Clone vagrant files
```
git clone https://github.com/lbernail/vagrant-puppet.git
```
* Go into puppet env, create puppet master and configure it (default box: hashicorp/precise64)
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


### Snaposhot fresh install
If you want to be able to go back to a clean puppetmaster (fresh from install, without having to do the full provisioning)
1. Install snaphost plugin
```
vagrant plugin install vagrant-vbox-snapshot
```
2. Snapshot VM
```
vagrant snapshot take puppetmaster freshinstall
```
3. After this you can go back to the snaphost if needed:
```
vagrant snapshot go puppetmaster freshinstall
```
You can find more information here: https://github.com/dergachev/vagrant-vbox-snapshot


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


### Add client virtual machines
websrv and dbsrv are configured in Vagrantfile (very easy to add new ones): same private network setup, hosts file configuration, no puppet
1. Create VM
```
vagrant up websrv
```
2. Connect to the box:
```
vagrant ssh websrv
```
3. Run puppet:
```
sudo /opt/puppetlabs/puppet/bin/puppet agent -t --server puppetmaster.vm.local
```  
This should fail because the certifcate is not signed
4. Sign certificate on *master*
```
sudo /opt/puppetlabs/puppet/bin/puppet cert sign websrv.vm.local
```
5. ReRun puppet on websrv
```
sudo /opt/puppetlabs/puppet/bin/puppet agent -t --server puppetmaster.vm.local
```  
*This will only give a notice: Default class for unknown node (from default node in site.pp).  
Puppetboard now shows 2 hosts*
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
