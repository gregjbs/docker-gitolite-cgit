#!/bin/sh

# Warning : this no standard docker entrypoint, we use dumb-init !

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

# If no cgitrc, let's copy one from /etc/cgitrc.default. This happens when bindmounting /home/git
if [ ! -f "/home/git/cgitrc" ]; then
	cp /etc/cgitrc.default /home/git/cgitrc
fi

# Gitolite configuration (admin pubkey)
if [ ! -f "/home/git/.ssh/authorized_keys" ]; then
  if [ -n "$SSH_KEY" ]; then
    echo "$SSH_KEY" > "/tmp/admin.pub"
    su - git -c "gitolite setup -pk \"/tmp/admin.pub\""
    rm "/tmp/admin.pub"
  else
    echo "You need to specify SSH_KEY on first run to setup gitolite"
    echo 'Example: docker run --rm -dit -v git-data:/home/git -v git-ssh:/etc/ssh -e SSH_KEY="$(cat /home/<user>/.ssh/id_rsa.pub)" gjbs84/gitolite-cgit:latest'
    exit 1
  fi
  echo "First launch : container is now shut down"
  halt
# Check setup at every startup
else
  su - git -c "gitolite setup"
fi

# Volume permissions
echo "Setting up permissions"
chown -R git:git /home/git
chmod -R 755 /home/git/repositories

# htaccess/htpasswd auth (comes from docker-cgit/scripts)
echo "No Apache htaccess required"
if [ "$HTTP_AUTH_PASSWORD" != "" ]; then
    echo "Enables Apache htaccess"
    echo "AuthType Basic
AuthName \"CGit\"
AuthUserFile /var/www/htdocs/cgit/.htpasswd
Require valid-user" > /var/www/htdocs/cgit/.htaccess
htpasswd  -c -b /var/www/htdocs/cgit/.htpasswd $HTTP_AUTH_USER $HTTP_AUTH_PASSWORD
fi

#exec "$@"

