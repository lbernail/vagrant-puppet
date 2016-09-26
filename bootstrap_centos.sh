echo "Bootstrapping"

release=`cat /etc/centos-release | cut -d " " -f 4 | cut -d "." -f 1`
env="production"

echo "Configuring puppetlabs repo"
wget -q https://yum.puppetlabs.com/puppetlabs-release-pc1-el-$release.noarch.rpm -O /tmp/puppetlabs.rpm
sudo rpm -i /tmp/puppetlabs.rpm > /dev/null
echo "Updating yum cache"
sudo yum check-update > /dev/null
echo "Installing puppet-agent and git"
sudo yum install -y puppet-agent git > /dev/null 2>&1


### eyaml configuration
echo "Copying keys /var/lib/puppet/secure"
mkdir -p /var/lib/puppet/secure
cp -r /vagrant/keys /var/lib/puppet/secure
useradd puppet
chown -R puppet:puppet /var/lib/puppet/secure
chmod 0500 /var/lib/puppet/secure/keys
chmod 0400 /var/lib/puppet/secure/keys/*

echo "Creating hiera.yaml"
cat > /etc/puppetlabs/puppet/hiera.yaml <<EOF
---
:backends:
  - eyaml
  - yaml
:logger: console
:hierarchy:
  - "nodes/%{::fqdn}"
  - common

:yaml:
   :datadir: /etc/puppetlabs/code/environments/%{::environment}/hieradata
:eyaml:
   :datadir: /etc/puppetlabs/code/environments/%{::environment}/hieradata
   :extension: 'yaml'
   :pkcs7_private_key: /var/lib/puppet/secure/keys/private_key.pkcs7.pem
   :pkcs7_public_key: /var/lib/puppet/secure/keys/public_key.pkcs7.pem
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

echo "Installing hiera-eyaml gem"
/opt/puppetlabs/puppet/bin/gem install hiera-eyaml --no-ri --no-rdoc > /dev/null

echo "Installing r10k gem"
/opt/puppetlabs/puppet/bin/gem install r10k --no-ri --no-rdoc > /dev/null
echo "Deploying with r10k"
/opt/puppetlabs/puppet/bin/r10k deploy environment -v -p


echo "Performing first puppet run"
# And remove default puppet.conf which raises warnings
sudo /opt/puppetlabs/puppet/bin/puppet apply /etc/puppetlabs/code/environments/$env/manifests --modulepath=/etc/puppetlabs/code/environments/$env/modules:/etc/puppetlabs/code/environments/$env/site --environment=$env
