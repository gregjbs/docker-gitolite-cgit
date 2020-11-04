Image docker Gitolite/cgit
=========================

This [Docker][docker] image offers a very quick way of deploying a Gitolite / Cgit server. Gitolite is a lightweight yet powerful git manager. Cgit is web-based frontend to Git repositories.

Based on Alpine Linux.
  
    
    
## Starting a gitolite-cgit container
    
### First launch

This first launch will create the server RSA keypair and make Gitolite initialization. `SSH_KEY` is the Gitolite admin's public RSA key. 
For more details about Gitolite setup, please read the [official documentation][gitolite_doc].

The container will stop by itself once the initial configuration is done. The `--rm` will make Docker remove it automatically. Only data will remain on the volume/bindmount.

    $ docker run --rm -dit -v git-data:/home/git -v git-ssh:/etc/ssh -e SSH_KEY="$(cat /home/<user>/.ssh/id_rsa.pub)" gjbs84/gitolite-cgit:latest

Default behavion is to save data into an internal named volume,  `git-data` and `git-ssh` in this exemple. Of course you can change it if you wish.

If it's suits you better you can use a bindmount. Here an exemple with `/srv/git-data` and `/srv/git-ssh`. No existing `repositories` directory must be there !  

    $ docker run --rm -dit -v /srv/git-data:/home/git -v /srv/git-ssh:/etc/ssh -e SSH_KEY="$(cat /home/<user>/.ssh/id_rsa.pub)" gjbs84/gitolite-cgit:latest
    
    
### Troubleshooting

If the initial startup fails, it can be usefull to repeat it one more time without the `--rm` option. 

The container will remains in stoped state and its logs will be available.

    $ docker logs git-test

A good first startup looks like this :

```sh
    Generating public/private rsa key pair.
    Your identification has been saved in /etc/ssh/ssh_host_rsa_key
    Your public key has been saved in /etc/ssh/ssh_host_rsa_key.pub
    The key fingerprint is:
    SHA256:4GcKIlWTPI5tpto3eqfHK30jBqM8U+eWoTp/tWSU2zs root@67dc97f12dd3
    The key's randomart image is:
    +---[RSA 3072]----+
    |   .o.           |
    |   .+.           |
    |  .+ ..  .       |
    | .. =. .o        |
    |. .+. ..So       |
    | ...+.o+= .      |
    | + o O.* . .     |
    |. B * % + E      |
    |  oXoX.+ . .     |
    +----[SHA256]-----+
    Generating public/private dsa key pair.
    Your identification has been saved in /etc/ssh/ssh_host_dsa_key
    Your public key has been saved in /etc/ssh/ssh_host_dsa_key.pub
    The key fingerprint is:
    SHA256:M5WtzLCBRcU6HtrRdBgOHvDkqa+DU3x5XaWC6VjXexU root@67dc97f12dd3
    The key's randomart image is:
    +---[DSA 1024]----+
    |      .o*ooo     |
    |       B =+o.  E.|
    |      . B+++.. o.|
    |       .=B=.o + .|
    |     ..+SO+o o ..|
    |      +.*oo . . .|
    |     o ...     . |
    |    o ..         |
    |     ...         |
    +----[SHA256]-----+
    Starting sshd
    Initialized empty Git repository in /home/git/repositories/gitolite-admin.git/
    Initialized empty Git repository in /home/git/repositories/testing.git/
    WARNING: /home/git/.ssh missing; creating a new one
        (this is normal on a brand new install)
    WARNING: /home/git/.ssh/authorized_keys missing; creating a new one
        (this is normal on a brand new install)
    First launch : container is now shut down
```

## Final launch 

You can now run the final container. It will use the previoulsy created volumes `git-data` and `git-ssh`. Now we can give a name to this container and we have to NAT ports 22 et 80 to the host. Of course you may have to adapt the command line to your network.

    $ docker run --name gitolite-cgit-srv -dit -v git-data:/home/git -v git-ssh:/etc/ssh -p 20080:80 -p 20022:22 gjbs84/gitolite-cgit:lastest
    
If you have chosen the bindmount way :

    $ docker run --name gitolite-cgit-srv -dit -v /srv/git-data:/home/git -v /srv/git-ssh:/etc/ssh -p 20080:80 -p 20022:22 gjbs84/gitolite-cgit:lastest

It's now time to check if everythings is right ! Let's clone the `testing` repository.

If you are new to Gitolite you have to know that every connection to it is made by the same user, commonly `git`. A very convenient way to proceed is to add an entry in your `~/.ssh/config` : 

    Host <server>
    Port 20022
    User git
    IdentityFile ~/.ssh/id_rsa

Of course you have to adapt this to your network once again.

Now you can easily clone the testing repo :

    $ git clone localhost:testing
    Cloning into 'testing'...
    Enter passphrase for key '/home/greg/.ssh/id_rsa': 
    warning: warning: You appear to have cloned an empty repository.
    Checking connectivity... done.

Git tells us this an empty repository, it's true so everything is fine so far.

## Updating / recreating container

If you have deleted the exiting container or wish to update it with a newer version, just run the "Final launch" step again. All your data are kept in Docker volume (or bindmount) .

### .htaccess authentication

You may wish to protect access to the git fronted Cgit. 

Just give fill up environnement variables `HTTP_AUTH_USER` and `HTTP_AUTH_PASSWORD` during the final launch step :

    $ docker run --name gitolite-cgit-srv -dit -v git-data:/home/git -v git-ssh:/etc/ssh -p 20080:80 -p 20022:22 -e HTTP_AUTH_USER="my_user" -e HTTP_AUTH_PASSWORD="my_password" gjbs84/gitolite-cgit:latest


### Troubleshooting

If you're experimenting some issue, start with having a loog into running container. Check health of `httpd` and `sshd` daemons.

To jump into the container :

    $ docker exec -ti git-test sh
    
Then check for `sshd` and `httpd` :

```
    $ ps
    PID   USER     TIME  COMMAND
        1 root      0:00 /usr/local/bin/dumb-init -- sh -c prepare-container.sh && exec httpd-foreground
        6 root      0:00 httpd -DFOREGROUND
       13 root      0:00 sshd: /usr/sbin/sshd [listener] 0 of 10-100 startups
       69 daemon    0:00 httpd -DFOREGROUND
       70 daemon    0:00 httpd -DFOREGROUND
       71 daemon    0:00 httpd -DFOREGROUND
       72 daemon    0:00 httpd -DFOREGROUND
       73 daemon    0:00 httpd -DFOREGROUND
```

## Using Gitolite and Cgit

### Cgit

Cgit is configured to automatically serve every repositories located into `/home/git/repositories` which is where Gitolite stores them. You basically have nothing to do to use it, just got to (adapt URL to the port number and server name) :

    http(s)://myserver:20080

You may want to custumize it (clone-prefix, favicon, headers...), just edit `/home/git/cgitrc`.


### Gitolite

This is not a Git/Gitolite course, but here is a very simple set of commands to quickly add a new repo to Gitolite. And a new non-admin user in the process.

1. Clone the `gitolite-admin` repository : 
    
        $ git clone myserver:gitolite-admin

2. Edit the `conf/gitolite.conf` file to add a repo :

        repo new_repo
        RW+     =   bob

3. Add Bob's public RSA key in `keydir/bob.pub` (of course you can use `admin` which already exists but it's not recommanded...). That's all you have to do to add a Gitolite user.

4. Add, commit and push the updated Gitolite configuration :

        $ git add keydir/bob.pub conf/gitolite.conf
        $ git commit -m "Added Bob and new_repo"
        $ git push --all

5. Now just add a remote site in you local `new_repo` repository and push a local branch to it !

        $ git remote add origin ssh://myserver:new_repo.git
        $ git push origin master


For more details, you'll have to check for official documentation of both projects !

  * [Gitolite][gitolite_admin] administration
  * [Cgit][cgit_page]


## Add existing repositories

First you must have an archive containing all you existing repositories.

They have to be BARE repositories ! No working copy should exist in any of them ! 

1. Jump into the container

2. Copy repos archive into the container.

    $ scp user@<your_host_local_ip>:/home/user/repos.tgz /tmp/

3. Untar archive into Gitolite repositories directory :

    $ cd /home/git/repositories
    $ tar -xf /tmp/repos.tgz
    $ rm /tmp/repos.tgz

4. Set permissions :

    $ chown -R git:git *
    $ chmod -R 755 *
    
5. From now you definitely should read [the official procedure][gitolite_existing_repo] before you go any further ! These commands come directly from there.

    $ su git
    $ cd
    $ gitolite compile
    $ gitolite setup --hooks-only
    $ gitolite trigger POST_COMPILE
    
6. Clone the Gitolite admin repository or go to your local copy and update the `gitolite.conf` with your new repositories info. Don't forget to add new users public key in `keydir` if needed. 

7. Add/commit/push and you're done ! Check everything is fine with the `info` command. You shoud see all the repositories you have access to, which means all of them (because you have the admin key).

        $ ssh git@myserver info

8. Adjust Cgit configuration in `/home/git/cgitrc` if you wish, but it will work out of the box.


## Building container image

In case you want to build you own image, clone from Github and build using the common Docker way (adjust or remove proxy settings according to your needs).

    $ docker build --build-arg HTTP_PROXY=http://192.168.0.1:3128  -t <image_name> .


## Voir aussi

* [Base image I used (httpd 2.4) ](https:https://hub.docker.com/_/httpd)
* [Gitolite image](http://github.com/sitaramc/gitolite#adding-users-and-repos)
* [Cgit image](https://github.com/invokr/docker-cgit)
* [Gitolite Documentation](https://gitolite.com/gitolite/index.html)

[docker]: https://www.docker.com/
[gitolite_doc]: https://gitolite.com/gitolite/install.html
[gitolite_admin]: https://gitolite.com/gitolite/basic-admin.html
[cgit_page]: https://git.zx2c4.com/cgit/about/
[gitolite_existing_repo]: https://gitolite.com/gitolite/basic-admin.html#appendix-1-bringing-existing-repos-into-gitolite
