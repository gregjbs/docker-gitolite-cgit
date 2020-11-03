Image docker Gitolite/cgit
=========================

Cette image [Docker][docker] permet de gérer sur Kyle les dépôts Git anciennent sur Cartman.
This image offers a very quick way of deploying a Gitolite / Cgit server. Gitolite is a lightweight yet powerful git manager. Cgit is web-based frontend to Git repositories.


## Building container image

Building is achieved by the common Docker way (adjust or remove proxy settings according to your needs):

    $ docker build --build-arg HTTP_PROXY=http://10.100.4.178:3128  -t gitolite-cgit .
  

## Relancer un nouveau conteneur avec les données déjà existantes

En cas de suppression du conteneur ou de mise à jour, il suffit de le lancer avec le nom du volume contenant les données. 
    
    
## Lancement du conteneur
    
### Premier lancement

Ce premier lancement va créer les clés SSH du serveur et effectuer la configuration initiale de Gitolite à partir de la clé publique fournie.
Le conteneur est conçu pour s'arrêter lui même une fois cette configuration terminée.
On utilise le paramètre `--rm` afin de détruire le conteneur immédiatement après son arrêt.

    $ docker run --rm --name git-test -dit -v git-data:/home/git -e SSH_KEY="$(cat /home/greg/.ssh/id_rsa.pub)" gitolite-cgit-cds:v20

Ici les données seront enregistrées dans un volume Docker interne nommé `git-data`. Ce nom peut être modifié sans incidence sur le fonctionnement.
    
Si on préfère utiliser un bindmount au lieu d'un volume Docker interne (ici `/srv/git-data`), le commande est la suivante. 
Il s'agit de l'option à privilégier en cas d'utilisation sur un NAS Synology, l'IHM ne permettant pas l'utilisation des volumes Docker fin 2020.

    $ docker run --rm --name git-test -dit -v /srv/git-data:/home/git -e SSH_KEY="$(cat /home/greg/.ssh/id_rsa.pub)" gitolite-cgit-cds:v20
    
    
### En cas de problème 
    
Si le premier lancement échoue ou si la suite de la procédure ne se déroule pas comme prévu, il peut être utile d'effectuer le premier lancement sans le paramètre `--rm`.

Les logs du conteneur sont alors accessibles :

    $ docker logs git-test

La sortie doit ressembler à ça :

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

## Lancement définitif 

Le lancement définitif du conteneur nécéssite de renseigner les ports de l'hôte qui seront NATés aux ports 22 et 80.
Le nom du volume interne ou le chemin du bindmount doivent bien sûr être identiques à ceux utilisés à l'étape précédente.

    $ docker run --name git-test -dit -v git-data:/home/git -p 8880:80 -p 2222:22 gitolite-cgit-cds:v20
    
La commande est analogue avec un bindmount (ici `/srv/git-data`) :

    $ docker run --name git-test -dit -v /srv/git-data:/home/git -p 8880:80 -p 2222:22 gitolite-cgit-cds:v20

Afin de tester le bon fonctionnement, on peut cloner le dépôt vide `testing` depuis la machine hôte. 

On commence par configurer son fichier `~/.ssh/config` : 

    Host localhost
    Port 2222
    User git
    IdentityFile ~/.ssh/id_rsa

Puis on clone le dépôt de test :

    $ git clone localhost:testing
    Clonage dans 'testing'...
    Enter passphrase for key '/home/greg/.ssh/id_rsa': 
    warning: Vous semblez avoir cloné un dépôt vide.
    Vérification de la connectivité... fait.

Git nous informe qu'il s'agit d'un dépôt vide, ce qui est normal. A ce stade tout fonctionne.

### Authentification par .htaccess

Il est possible de protéger l'accès à Cgit par un couple utilisateur / mot de passe. 
Il suffit de renseigner les variables d'environnement `HTTP_AUTH_USER` et `HTTP_AUTH_PASSWORD` dans la ligne de lancement du conteneur :

    $ docker run --name git-test -dit -v git-data:/home/git -p 8880:80 -p 2222:22 -e HTTP_AUTH_USER="my_user" -e HTTP_AUTH_PASSWORD="my_password" gitolite-cgit-cds:v21
    
Un couple de fichier .htaccess / .htpasswd est alors généré à la création du conteneur.



### En cas de problème

En cas de défaillance du conteneur, la première chose à faire est de s'y connecter et de vérifier  l'état des service `httpd` et `sshd`.


Pour rentrer dans le conteneur :

    $ docker exec -ti git-test sh
    
On peut vérifier que les processus `sshd` et `httpd` tournent bien :

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
    

## Ajout des dépôts existants à Gitolite & Cgit

Attention, cette méthode supprime les hook d'update !

1. Se connecter au conteneur

2. Copier l'archive des dépôts : uniquement des bare repositories (sans copie de travail) se terminant par ".git" :

    $ scp greg@172.17.0.1:/opt/vm/repos/cartman-gitosis-repo.tgz /tmp/
    
Une manière de procéder est de créer un utilisateur temporaire dont le fichier ~/.ssh/authorized/keys contient votre clé publique puis :

    $ scp -P <port> existing-repos.tgz tmp_user@10.16.0.217:/tmp/

3. Décompresser l'archive dans le répertoire des dépôts de Gitolite :

    $ cd /home/git/repositories
    $ tar -xf /tmp/cartman-gitosis-repo.tgz
    $ rm /tmp/cartman-gitosis-repo.tgz

4. Régler les permissions :

    $ chown -R git:git *
    $ chmod -R 755 *
    
5. Exécuter les commandes d'admin Gitolite (voir documentation pour plus de détails)

    $ su git
    $ cd
    $ gitolite compile
    $ gitolite setup --hooks-only
    $ gitolite trigger POST_COMPILE
    
6. Clôner le dépot d'administration Gitosis afin d'y modifier en conséquence le fichier `gitolite.conf` et ajouter les clés des utilisateurs dans `keydir`

7. Commiter et pousser les changements

8. Ajuster la configuration de cgit dans `/home/git/cgitrc`



## Utilisation de Gitolite & Cgit

Gitolite tout comme son ancètre Gitosis identifie les utilisateurs par la clés publique qu'ils utilisent. Ces utilisateurs n'ont donc aucun rapport avec ceux connus du système. Toutes connexions vers Gitolite se feront ainsi avec l'utilisateur `git` associé à votre clé publique.

- Clonage d'un dépôt
- Ajout d'un nouveau dépôt (Gitolite + Cgit)
- Push/Pull
- Gestion des utilisateurs et des permissions Gitolite


## Configurer le proxy pour Git

En cas de besoin, ces deux commandes renseignent le fichier ~/.gitrc avec l'adresse d'un serveur proxy.

    $ git config --global http.https://github.com.proxy http://10.100.4.178:3128
    $ git config --global http.https://github.com.sslVerify false
    
Pour ajouter une entrée dans le fichier `~\.gitconfig`.

## Voir aussi

* [Image de base utilisée (httpd 2.4) ](https:https://hub.docker.com/_/httpd)
* [Exemple d'image gitolite](http://github.com/sitaramc/gitolite#adding-users-and-repos)
* [Exemple d'image cgit](https://github.com/invokr/docker-cgit)
* [Documentation officielle Gitolite](https://gitolite.com/gitolite/basic-admin.html)
* [Sauvegarde et restauration d'un conteneur et de ses volumes](https://docs.docker.com/storage/volumes/#backup-a-container)

[docker]: https://www.docker.com/
