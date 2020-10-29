# Inspired from https://github.com/invokr/docker-cgit/blob/master/Dockerfile
# https://hub.docker.com/_/httpd 
# Usefull help on cgit : https://wiki.archlinux.org/index.php/Cgit#Configuration_of_cgit

FROM httpd:2.4-alpine

MAINTAINER Grégory Joubès <gregjbs@protonmail.com>

WORKDIR /root

# Proxy, comment if not needed
ARG HTTP_PROXY

# Packages 
RUN apk update && apk add git openssh  
RUN apk add gcc make libressl-dev 
RUN apk add python3 py3-pygments
RUN apk add py3-markdown
RUN apk add linux-headers 
RUN ln -sf /usr/include/linux/unistd.h /usr/include/
RUN apk add musl-dev
RUN apk add libintl musl-libintl
RUN apk add zlib zlib-dev
# to support untar tar.xz
RUN apk add tar
# Confort...
RUN apk add vim

# Clean up
RUN rm  -rf /tmp/* /var/cache/apk/*

# cgit install (uncomment prefered method : local archive / clone)
WORKDIR /root
# Clone
#RUN git clone git://git.zx2c4.com/cgit
# Local archive (3 lines)
COPY cgit-1.2.3.tar.xz /root/cgit-1.2.3.tar.xz
RUN tar xf cgit-1.2.3.tar.xz
RUN mv cgit-1.2.3 cgit
#####
WORKDIR cgit
# Uncomment these 2 lines if cloning
#RUN git submodule init 
#RUN git submodule update
# Uncomment these 2 line if building from local archive
COPY git-2.25.1.tar.xz /root/cgit/git-2.25.1.tar.xz
RUN tar -xJf git-2.25.1.tar.xz && rm -rf git && mv git-2.25.1 git
# Building now !
RUN make install NO_LUA=1 NO_REGEX=NeedsStartEnd
WORKDIR ../
RUN rm -Rf cgit

# cgit config
ENV HTTP_AUTH_USER="", HTTP_AUTH_PASSWORD=""
ADD httpd.conf /usr/local/apache2/conf/httpd.conf
ADD cgitrc /home/git/cgitrc
# Extra copy if /home/git is bindmounted
ADD cgitrc /etc/cgitrc.default
RUN ln -s /home/git/cgitrc /etc/cgitrc

# Gitolite install (uncomment prefered method : local archive / clone)
# Clone
#RUN git clone https://github.com/sitaramc/gitolite
# Local archive (2 lines)
COPY gitolite-3.6.12.tar.gz /root/gitolite-3.6.12.tar.gz
RUN tar xf gitolite-3.6.12.tar.gz
#####
RUN gitolite/install -to /usr/local/bin/

# Default work dir for base image httpd
WORKDIR /usr/local/apache2

# Pre-launch script
ADD prepare-container.sh /usr/local/bin
RUN chmod +x /usr/local/bin/prepare-container.sh

# SSHD config : no password, no strict mode
ADD sshd_config /etc/ssh/sshd_config

# Remove SSH keyes, fresh keys will be generated at container startup by prepare-container.sh
RUN rm -rf /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key

# Gitolis / Gitolite
RUN adduser -D -g "" -s "/bin/ash" git
# We need a password set, otherwise pubkey auth doesn't work... why ?? /sbin/nologin doesn't work either
RUN echo "git:zkndflsi67hGT75!dad#" | chpasswd

# Volume for /home/git
VOLUME ["/home/git"]

# Ports
EXPOSE 80
EXPOSE 22

# Minimal INIT system, cf https://github.com/Yelp/dumb-init/
# (ADD can pull from URL or local directory)
#ADD https://github.com/Yelp/dumb-init/releases/download/v1.0.0/dumb-init_1.0.0_amd64 /usr/local/bin/dumb-init
ADD dumb-init_1.0.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

# Removing proxy
#RUN export http_proxy="” https_proxy=""

# Runs "/usr/bin/dumb-init -- sh -c  prepare-container.sh && exec apachectl -DFOREGROUND"
# dumb-init gets PID 1 and handles signlas gracefully
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["sh", "-c", "prepare-container.sh && exec httpd-foreground"]

# To work without dumb-init, uncomment last line in prepare-container.sh to make it usual Docker entrypoint
#ENTRYPOINT ["prepare-container.sh"]
# CMD comes from httpd Dockerfile. If no dumb-init, use this CMD statement
#CMD ["httpd-foreground"]

# For testing purpose
#CMD ["sh", "-c", "prepare-container.sh && exec nc -l 80"]



