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
wget -q https://apt.puppetlabs.com/puppetlabs-release-pc1-$release.deb -O /tmp/puppetlabs.deb
dpkg -i /tmp/puppetlabs.deb > /dev/null
echo "Updating apt cache"
apt-get update > /dev/null
echo "Installing puppet-agent and git"
apt-get install -y puppet-agent git > /dev/null 2>&1

### GPG configuration
#echo "Installing hiera-gpg"
#gem install hiera-gpg --no-ri --no-rdoc > /dev/null
#echo "Copying keyrings to root dir (for puppet apply) and to /var/lib/puppet (for puppet agents)"
#rm -rf /root/.gnupg
#cp -r /vagrant/gpg /root/.gnupg
#rm -rf /var/lib/puppet/.gnupg
#mkdir -p /var/lib/puppet/
#cp -r /vagrant/gpg /var/lib/puppet/.gnupg
#chown -R puppet:puppet /var/lib/puppet/.gnupg/

echo "Creating hiera.yaml"
cat > /etc/puppetlabs/puppet/hiera.yaml <<EOF
---
:backends:
  - yaml
:logger: console
:hierarchy:
  - "nodes/%{::fqdn}"
  - common

:yaml:
   :datadir: /etc/puppetlabs/code/environments/%{::environment}/hieradata
EOF

echo "Creating r10k.yaml"
rm -rf /etc/puppetlabs/code/environments/*
mkdir -p /etc/puppetlabs/r10k
cat > /etc/puppetlabs/r10k/r10k.yaml <<EOF
---
:cachedir: /var/cache/r10k
:sources:
  :local:
    remote: https://github.com/lbernail/puppet-r10k.git
    basedir: /etc/puppetlabs/code/environments
EOF


echo "Installing r10k gem"
# Also install timer to avoid warning with ruby 1.8
/opt/puppetlabs/puppet/bin/gem install r10k --no-ri --no-rdoc > /dev/null
#gem install r10k --no-ri --no-rdoc > /dev/null
#gem install system_timer --no-ri --no-rdoc > /dev/null
echo "Deploying with r10k"
/opt/puppetlabs/puppet/bin/r10k deploy environment -v -p


echo "Performing first puppet run"
# And remove default puppet.conf which raises warnings
/opt/puppetlabs/puppet/bin/puppet apply /etc/puppetlabs/code/environments/$env/manifests --modulepath=/etc/puppetlabs/code/environments/$env/modules:/etc/puppetlabs/code/environments/$env/site-modules --environment=$env

