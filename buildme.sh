docker build -t yantis/archlinux-small-ssh-hpn .

docker run \
  -ti \
  --rm \
  -v $HOME/.ssh/authorized_keys:/authorized_keys:ro \
  -h docker \
  -p 49158:22 \
  yantis/archlinux-small-ssh-hpn

# --privileged \
