############################################################
# Dockerfile for SSH with high performance patch.
#
# Based on Arch Linux
############################################################

FROM yantis/archlinux-small
MAINTAINER Jonathan Yantis <yantis@yantis.net>

ENV TERM xterm

# Update and force a refresh of all package lists even if they appear up to date.
RUN pacman -Syyu --noconfirm

# Install open ssh
# RUN pacman --noconfirm -S openssh

# Install SSH with the high performance patch.
# REM this section to not use the high performance patch
#### - SSH-HP START #########
USER docker
RUN sudo pacman --noconfirm -S yaourt gcc make git autoconf fakeroot binutils && \
    yaourt --noconfirm -S openssh-hpn-git && \
    sudo pacman --noconfirm -Rs yaourt gcc make git autoconf fakeroot binutils

USER root
# Allow clients to use the NONE cipher
# http://www.psc.edu/index.php/hpn-ssh/640
RUN echo "NoneEnabled=yes" >> /etc/ssh/sshd_config
RUN pacman --noconfirm -Rs linux-headers openbsd-netcat
#### - SSH-HP END #########

# Setup our SSH
RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \

    # Disable PAM so the container doesn't need privs.
    sed -i "s/UsePAM yes/UsePAM no/" /etc/ssh/sshd_config && \

    # Some people have more than 6 keys in memory. Lets allow up to 30 tries.
    echo "MaxAuthTries 30" >> /etc/ssh/sshd_config && \

    touch /var/log/lastlog && \
    chgrp utmp /var/log/lastlog && \
    chmod 664 /var/log/lastlog && \

    mkdir $HOME/.ssh

# Add in an.ssh directory for our user.
RUN mkdir /home/docker/.ssh && \
    chown docker:users /home/docker/.ssh

##########################################################################
# CLEAN UP SECTION - THIS GOES AT THE END                                #
##########################################################################
RUN localepurge && \

    # Remove info, man and docs
    # rm -r /usr/share/info/* && \
    # rm -r /usr/share/man/* && \
    # rm -r /usr/share/doc/* && \

    # Delete any backup files like /etc/pacman.d/gnupg/pubring.gpg~
    find /. -name "*~" -type f -delete && \

    # Keep only xterm related profiles in terminfo.
    find /usr/share/terminfo/. ! -name "*xterm*" ! -name "*screen*" ! -name "*screen*" -type f -delete && \

    # Remove anything left in temp.
    rm -r /tmp/*

RUN bash -c "echo 'y' | pacman -Scc >/dev/null 2>&1" && \
    paccache -rk0 >/dev/null 2>&1 &&  \
    pacman-optimize && \
    rm -r /var/lib/pacman/sync/*

# Dynamically accept either passed in keys OR password but not both.
# And make it so it doesn't matter what UID the authorized_keys volume is.
ADD keyfix/keyfix.sh /usr/bin/keyfix
RUN chmod +x /usr/bin/keyfix

ADD openssh service/openssh

CMD ["/init"]

# Tests
# ssh docker@54.186.243.203 -p 49158 -oCipher=aes128-ctr
# ssh docker@54.186.243.203 -p 49158 -oNoneEnabled=true -oNoneSwitch=yes
