master="puppetmaster.vm.local"

echo "Installing puppet"
release=`cat /etc/centos-release | cut -d " " -f 4 | cut -d "." -f 1`

echo "Configuring puppetlabs repo"
wget -q https://yum.puppetlabs.com/puppetlabs-release-pc1-el-$release.noarch.rpm -O /tmp/puppetlabs.rpm
sudo rpm -i /tmp/puppetlabs.rpm > /dev/null
echo "Updating yum cache"
sudo yum check-update > /dev/null
echo "Installing puppet-agent"
sudo yum install -y puppet-agent > /dev/null 2>&1
useradd puppet
chown -R puppet:puppet /etc/puppetlabs

echo "Run puppet"
sudo /opt/puppetlabs/puppet/bin/puppet agent -t --server $master
echo "Bootstrap done"
echo "If you saw a cert issue, sign it on master and rerun puppet agent -t --server $master"

echo "Delete iptables rules"
sudo iptables --flush > /dev/null 2>&1
sudo service iptables save > /dev/null 2>&1
