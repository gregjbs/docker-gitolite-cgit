FROM httpd:2.4-alpine

MAINTAINER Grégory J. <gregjbs@protonmail.com>

WORKDIR /root

ARG HTTP_PROXY

WORKDIR /root

# Packages we'll keep
RUN apk update && apk add git openssh && \  
    apk add python3 py3-pygments && \
    apk add py3-markdown && \
    apk add libintl musl-libintl && \
    apk add zlib

# cgit install
RUN git clone git://git.zx2c4.com/cgit
WORKDIR cgit
# Packages needed for build
RUN apk update && apk add gcc make libressl-dev  && \  
    apk add linux-headers && \
    ln -sf /usr/include/linux/unistd.h /usr/include/ && \
    apk add musl-dev zlib-dev && \
# Build
    git submodule init && \
    git submodule update && \
    make install NO_LUA=1 NO_REGEX=NeedsStartEnd && \
# Clean up
    cd ../ && \
    rm -Rf cgit && \
    apk del gcc make libressl-dev && \
    apk del linux-headers musl-dev zlib-dev && \
    rm  -rf /tmp/* /var/cache/apk/*
WORKDIR /root

# cgit config
ENV HTTP_AUTH_USER="", HTTP_AUTH_PASSWORD=""
ADD httpd.conf /usr/local/apache2/conf/httpd.conf
ADD cgitrc /home/git/cgitrc
# Extra copy if /home/git is bindmounted
ADD cgitrc /etc/cgitrc.default
RUN ln -s /home/git/cgitrc /etc/cgitrc

# Gitolite install
# Clone
RUN git clone https://github.com/sitaramc/gitolite && \
    gitolite/install -to /usr/local/bin/

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
RUN echo "git:fhzefGG65gdoejdK$!dhd753" | chpasswd

# Volume for server key
VOLUME ["/etc/ssh"]

# Volume for /home/git
VOLUME ["/home/git"]

# Ports
EXPOSE 80
EXPOSE 22

# Minimal INIT system, cf https://github.com/Yelp/dumb-init/
ADD https://github.com/Yelp/dumb-init/releases/download/v1.0.0/dumb-init_1.0.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

# Runs "/usr/bin/dumb-init -- sh -c  prepare-container.sh && exec apachectl -DFOREGROUND"
# dumb-init gets PID 1 and handles signals gracefully
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["sh", "-c", "prepare-container.sh && exec httpd-foreground"]

# To work without dumb-init, uncomment last line in prepare-container.sh to make it usual Docker entrypoint.
# Use following CMD statement which comes from httpd Dockerfile. 
# Comment previous ENTRYPOINT and CMD.
#ENTRYPOINT ["prepare-container.sh"]
#CMD ["httpd-foreground"]
