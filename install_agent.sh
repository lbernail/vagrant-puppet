echo "Installing puppet"

release=`grep DISTRIB_CODENAME /etc/lsb-release | cut -d "=" -f 2`

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
echo "Installing puppet-agent"
apt-get install -y puppet-agent > /dev/null 2>&1
