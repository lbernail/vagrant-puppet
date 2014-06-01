echo "Bootstrapping"

release=`grep DISTRIB_CODENAME /etc/lsb-release | cut -d "=" -f 2`
env="production"

echo "Modifying apt sources to rely on AWS Europe"
cat > /etc/apt/sources.list <<EOF
deb http://eu-west-1.ec2.archive.ubuntu.com/ubuntu/ ${release} main restricted universe multiverse
deb http://eu-west-1.ec2.archive.ubuntu.com/ubuntu/ ${release}-updates main restricted universe multiverse
deb http://eu-west-1.ec2.archive.ubuntu.com/ubuntu/ ${release}-security main restricted universe multiverse
EOF


echo "Configuring puppetlabs repo"
wget -q https://apt.puppetlabs.com/puppetlabs-release-$release.deb -O /tmp/puppetlabs.deb
dpkg -i /tmp/puppetlabs.deb > /dev/null
echo "Updading apt cache"
apt-get update > /dev/null
echo "Installing puppet, rubygems and git"
apt-get install -y puppet rubygems git > /dev/null 2>&1

## GPG configuration
echo "Installing hiera-gpg"
gem install hiera-gpg --no-ri --no-rdoc > /dev/null
echo "Copying keyrings to root dir (for puppet apply) and to /var/lib/puppet (for puppet agents)"
rm -rf /root/.gnupg
cp -r /vagrant/gpg /root/.gnupg
rm -rf /var/lib/puppet/.gnupg
mkdir -p /var/lib/puppet/
cp -r /vagrant/gpg /var/lib/puppet/.gnupg
chown -R puppet:puppet /var/lib/puppet/.gnupg/

echo "Creating hiera.yaml"
cat > /etc/puppet/hiera.yaml <<EOF
---
:backends:
  - yaml
  - gpg
:logger: console
:hierarchy:
  - "fqdn/%{::fqdn}"
  - common

:yaml:
   :datadir: /etc/puppet/environments/%{::environment}/hieradata

:gpg:
   :datadir: /etc/puppet/environments/%{::environment}/hieradata
EOF

echo "Creating r10k.yaml"
cat > /etc/r10k.yaml <<EOF
---
:cachedir: /var/cache/r10k
:sources:
  :local:
    remote: https://github.com/lbernail/puppet-r10k.git
    basedir: /etc/puppet/environments
EOF


echo "Installing r10k gem"
# Also install timer to avoid warning with ruby 1.8
gem install r10k --no-ri --no-rdoc > /dev/null
gem install system_timer --no-ri --no-rdoc > /dev/null
echo "Deploying with r10k"
r10k deploy environment -p


echo "ETCD client configuration"
#mkdir /opt/etcd
#wget -q https://github.com/coreos/etcd/releases/download/v0.4.1/etcd-v0.4.1-linux-amd64.tar.gz -O - | tar -xzC /opt/etcd --strip-components 1
#export PATH=$PATH:/opt/etcd
#PEER=192.168.128.3:4001
#etcdctl --peers $PEER ls /puppet_enc $> /dev/null || etcdctl --peers $PEER mkdir /puppet_enc
#etcdctl --peers $PEER set puppet_enc/puppetmaster.vm.local "classes: [common::roles::puppetmaster]"


echo "Performing first puppet run"
# And remove default puppet.conf which raises warnings
rm /etc/puppet/puppet.conf
puppet apply /etc/puppet/environments/$env/manifests --modulepath=/etc/puppet/environments/$env/modules:/etc/puppet/environments/$env/site-modules --environment=$env

