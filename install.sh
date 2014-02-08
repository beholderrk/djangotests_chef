#!/bin/bash

# This runs as root on the server

chef_binary=/var/lib/gems/1.9.1/gems/chef-11.10.0/bin/chef-solo

# Are we on a vanilla system?
if ! test -f "$chef_binary"; then
    export DEBIAN_FRONTEND=noninteractive
    # Upgrade headlessly (this is only safe-ish on vanilla systems)
    apt-get update &&
    apt-get -o Dpkg::Options::="--force-confnew" \
        --force-yes -fuy dist-upgrade &&
    # Install Ruby and Chef
    apt-get install -y rubygems ruby1.9.1 ruby1.9.1-dev &&
    gem install --no-rdoc --no-ri chef
fi &&

chef-solo -c solo.rb