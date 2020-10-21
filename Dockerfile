# Inspired from https://github.com/invokr/docker-cgit/blob/master/Dockerfile
# https://hub.docker.com/_/httpd 
# Usefull help on cgit : https://wiki.archlinux.org/index.php/Cgit#Configuration_of_cgit

FROM httpd:2.4-alpine

MAINTAINER Grégory Joubès <greg@cds.lan>

WORKDIR /root

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
# Confort...
RUN apk add vim

# Clean up
RUN rm  -rf /tmp/* /var/cache/apk/*

# cgit install
RUN git clone git://git.zx2c4.com/cgit
WORKDIR cgit
RUN git submodule init 
RUN git submodule update
RUN make install NO_LUA=1 NO_REGEX=NeedsStartEnd
WORKDIR ../
RUN rm -Rf cgit
WORKDIR /usr/local/apache2

# cgit config
ENV HTTP_AUTH_USER="", HTTP_AUTH_PASSWORD=""
ADD httpd.conf /usr/local/apache2/conf/httpd.conf
RUN ln -s /home/git/cgitrc /etc/cgitrc

# Pre-launch script
ADD prepare-container.sh /usr/local/bin
RUN chmod +x /usr/local/bin/prepare-container.sh

# Remove SSH keyes, fresh keys will be generated at container startup by prepare-container.sh
RUN rm -rf /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key

# Gitolis / Gitolite
RUN adduser -D -g "" -s "/sbin/nologin" git
RUN ln -s /home/git/repositories/gitosis-admin.git/gitosis.conf /home/git/.gitosis.conf

# Pour passer sur l'user git
#USER git
#WORKDIR /home/git

# Ports
EXPOSE 80
EXPOSE 22

# Minimal INIT system, cf https://github.com/Yelp/dumb-init/
# (ADD can pull from URL or local directory)
#ADD https://github.com/Yelp/dumb-init/releases/download/v1.0.0/dumb-init_1.0.0_amd64 /usr/local/bin/dumb-init
ADD dumb-init_1.0.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

# Runs "/usr/bin/dumb-init -- sh -c  prepare-container.sh && exec apachectl -DFOREGROUND"
# dumb-init gets PID 1 and handles signlas gracefully
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
# sh only lives to run prepare-container.sh (thanks to 'exec') 
CMD ["sh", "-c", "prepare-container.sh && exec httpd-foreground"]

# To work without dumb-init, uncomment last line in prepare-container.sh to make it usual Docker entrypoint
#ENTRYPOINT ["prepare-container.sh"]
# CMD comes from httpd Dockerfile. If no dumb-init, use this CMD statement
#CMD ["httpd-foreground"]

# For testing purpose
#CMD ["sh", "-c", "prepare-container.sh && exec nc -l 80"]



