#!/usr/bin/env -S bash -e

# bash <(curl -s https://jgus.github.io/nixos-config/install/init.sh)

echo "### Setting up SSH..."
mkdir -p ~/.ssh || true
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
curl https://github.com/jgus.keys >> ~/.ssh/authorized_keys
uniq -i ~/.ssh/authorized_keys
chmod 400 ~/.ssh/authorized_keys

BRANCH=${BRANCH:-main}
echo "### Downlaoding repo (${BRANCH})..."
cd /
curl -sL https://github.com/jgus/nixos-config/archive/${BRANCH}.tar.gz | tar -xz --strip-components=1 nixos-config-${BRANCH}/install
find /install -iname \*.sh -exec chmod a+x {} \;

echo "### System prep complete; SSH available at:"
ip a | grep inet
