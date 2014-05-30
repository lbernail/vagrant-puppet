# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

SUBNET="192.168.128"
DOMAIN="vm.local"

MASTERNAME="puppetmaster"
DOCKERS="dockers"
MASTERIP="#{SUBNET}.2"
DOCKERSIP="#{SUBNET}.3"
AGENTS=["dbsrv","websrv"]


#Generate a host file to share
$hostfiledata="127.0.0.1 localhost\n#{MASTERIP} #{MASTERNAME}.#{DOMAIN} #{MASTERNAME}"
$hostfiledata=$hostfiledata+"\n#{DOCKERSIP} #{DOCKERS}.#{DOMAIN} #{DOCKERS}"
AGENTS.each_with_index do |agent,index|
  $hostfiledata=$hostfiledata+"\n#{SUBNET}.#{index+10} #{agent}.#{DOMAIN} #{agent}"
end

$set_host_file="cat <<EOF > /etc/hosts\n"+$hostfiledata+"\nEOF\n"

Vagrant.configure VAGRANTFILE_API_VERSION do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end
  
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.define :puppetmaster do |pm|
    pm.vm.box = "hashicorp/precise64"
    pm.vm.hostname = "#{MASTERNAME}.#{DOMAIN}"
    pm.vm.network :private_network, ip: "#{MASTERIP}" 
    pm.vm.network :forwarded_port, guest: 5000, host: 5000
    pm.vm.provision :shell, :inline => $set_host_file
    pm.vm.provision :shell, :path => "bootstrap.sh"
  end

  AGENTS.each_with_index do |agent,index|
    config.vm.define "#{agent}".to_sym do |ag|
        ag.vm.box = "hashicorp/precise64"
        ag.vm.hostname = "#{agent}.#{DOMAIN}"
        ag.vm.network :private_network, ip: "#{SUBNET}.#{index+10}"
        ag.vm.provision :shell, :inline => $set_host_file
    end
  end  

  config.vm.define :dockers do |d|

    d.vm.box = "mitchellh/boot2docker"

    d.vm.network :private_network, ip: "#{DOCKERSIP}"
    d.vm.network :forwarded_port, guest: 4001, host: 4001
    d.vm.network :forwarded_port, guest: 7001, host: 7001

#d.vm.provision :file, source:"etcd/Dockerfile", destination:"/home/docker/etcd/Dockerfile"
#    d.vm.provision :shell, :inline => "docker build -t etcd /home/docker/etcd"
#    d.vm.provision :shell, :inline => "docker run -d -p 4001:4001 -p 7001:7001 --name etcd etcd"
    d.vm.provision :shell, :inline => "kill `cat /var/run/udhcpc.eth1.pid`"   # Workaround tinycore dhcp issue
    d.vm.provision :shell, :inline => "docker pull coreos/etcd"
    d.vm.provision :shell, :inline => "docker run -d -p 4001:4001 -p 7001:7001 --name etcd coreos/etcd -addr #{DOCKERSIP}:4001"
  end
end
