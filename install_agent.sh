echo "Installing puppet"

release=`grep DISTRIB_CODENAME /etc/lsb-release | cut -d "=" -f 2`

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
echo "Installing puppet"
# And remove default puppet.conf which raises warnings
apt-get install -y puppet > /dev/null 2>&1
rm /etc/puppet/puppet.conf
