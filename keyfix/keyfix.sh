#!/bin/bash

# Ran into a problem with the user docker directory being owned by 
# root in some instances. I think it is related to issue #1295
chown -R docker /home/docker
chgrp -R docker /home/docker

# The concept here is to use authorized keys if the user provided them
# and if they didn't then allow password access.

if [ -f /authorized_keys ]; then
  >&2 echo "Adding authorized keys for root"
  mkdir -p /root/.ssh
  cp /authorized_keys /root/.ssh/

  # authorize our user docker
  >&2 echo "Adding authorized keys for user docker"
  mkdir -p /home/docker/.ssh
  cp /authorized_keys /home/docker/.ssh/
  chown -R docker /home/docker/.ssh
  chgrp -R docker /home/docker/.ssh
else
  >&2 echo "No authorized keys so letting users login with a password."
  sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config

fi
exit 0

# vim:set ts=2 sw=2 et:
