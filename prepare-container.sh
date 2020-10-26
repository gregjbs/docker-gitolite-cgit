#!/bin/sh

# From https://github.com/danielguerra69/alpine-sshd/blob/master/docker-entrypoint.sh
# Comme on utilise dumb-init, ce fichier n'est plus un entrypoint, mais un simple script de préparation

if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
	# generate fresh rsa key
	ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
	# generate fresh dsa key
	ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

#prepare run dir
if [ ! -d "/var/run/sshd" ]; then
  mkdir -p /var/run/sshd
fi

# Run sshd
echo "Starting sshd"
/usr/sbin/sshd

# Si le fichier cgitrc n'est pas présent, on le copie depuis /etc/cgitrc.default. Cela arrive en cas de bindmount sur /home/git
if [ ! -f "/home/git/cgitrc" ]; then
	cp /etc/cgitrc.default /home/git/cgitrc
fi

# Permissions du volume pour les repos
echo "Setting up permissions"
chown -R git:git /home/git

# Gitolite configuration (admin pubkey)
if [ ! -f ~git/.ssh/authorized_keys ]; then
  if [ -n "$SSH_KEY" ]; then
    echo "$SSH_KEY" > "/tmp/admin.pub"
    su - git -c "gitolite setup -pk \"/tmp/admin.pub\""
    rm "/tmp/admin.pub"
  else
    echo "You need to specify SSH_KEY on first run to setup gitolite"
    echo 'Example: docker run -e SSH_KEY="$(cat ~/.ssh/id_rsa.pub)" -e SSH_KEY_NAME="$(whoami)" jgiannuzzi/gitolite'
    exit 1
  fi
# Check setup at every startup
else
  su - git -c "gitolite setup"
fi


# Authentification par htaccess. Récupérer de docker-cgit/scripts
echo "Enables Apache htaccess if needed"
if [ "$HTTP_AUTH_PASSWORD" != "" ]; then
    echo "AuthType Basic
AuthName \"CGit\"
AuthUserFile /var/www/htdocs/cgit/.htpasswd
Require valid-user" > /var/www/htdocs/cgit/.htaccess
htpasswd  -c -b /var/www/htdocs/cgit/.htpasswd $HTTP_AUTH_USER $HTTP_AUTH_PASSWORD
fi

#exec "$@"

