echo "Bootstrapping"

release=`grep DISTRIB_CODENAME /etc/lsb-release | cut -d "=" -f 2`
version="3.6.0-1puppetlabs1"

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
apt-get install -y puppet-common=$version puppet=$version > /dev/null 2>&1
apt-get install -y rubygems git > /dev/null 2>&1

echo "Creating hiera.yaml"
cat > /etc/puppet/hiera.yaml <<EOF
---
:backends:
  - yaml
:logger: console
:hierarchy:
  - "fqdn/%{::fqdn}"
  - common

:yaml:
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
gem install r10k > /dev/null
gem install system_timer > /dev/null
echo "Deploying with r10k"
git config --system  http.sslVerify "false"
r10k deploy environment -p

echo "Performing first puppet run"
puppet apply /etc/puppet/environments/production/manifests/site.pp --modulepath=/etc/puppet/environments/production/modules:/etc/puppet/environments/production/site-modules
