#!/bin/bash

# Usage: ./deploy.sh [host]

host="${1:-root@78.47.249.27}"

# The host key might change when we instantiate a new VM, so
# we remove (-R) the old host key from known_hosts
ssh-keygen -R "${host#*@}" 2> /dev/null

ssh -o 'StrictHostKeyChecking no' -t "$host" 'sudo rm -rf ~/chef'
tar cj . | ssh -o 'StrictHostKeyChecking no' -t "$host" 'mkdir ~/chef && cd ~/chef && tar xj'