# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

SUBNET="192.168.128"
DOMAIN="vm.local"

MASTERNAME="puppetmaster"
MASTERIP="#{SUBNET}.2"
AGENTS=["dbsrv","websrv"]


#Generate a host file to share
$hostfiledata="127.0.0.1 localhost\n#{MASTERIP} #{MASTERNAME}.#{DOMAIN} #{MASTERNAME}"
AGENTS.each_with_index do |agent,index|
  $hostfiledata=$hostfiledata+"\n#{SUBNET}.#{index+10} #{agent}.#{DOMAIN} #{agent}"
end

$bootstrap=File.read("bootstrap.sh")

$set_host_file="cat <<EOF > /etc/hosts\n"+$hostfiledata+"\nEOF\n"

Vagrant.configure VAGRANTFILE_API_VERSION do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end

  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.define :puppetmaster do |pm|
     pm.vm.box = "hashicorp/precise64"
     pm.vm.hostname = "#{MASTERNAME}.#{DOMAIN}"
     pm.vm.network :private_network, ip: "#{MASTERIP}" 
     pm.vm.network :forwarded_port, guest: 5000, host: 5000
     pm.vm.provision :shell, :inline => $set_host_file
     pm.vm.provision :shell, :inline => $bootstrap
  end

  AGENTS.each_with_index do |agent,index|
    config.vm.define "#{agent}".to_sym do |ag|
        ag.vm.box = "hashicorp/precise64"
        ag.vm.hostname = "#{agent}.#{DOMAIN}"
        ag.vm.network :private_network, ip: "#{SUBNET}.#{index+10}"
        ag.vm.provision :shell, :inline => $set_host_file
    end
  end  
end
