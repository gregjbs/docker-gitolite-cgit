Image docker Gitolite/cgit
=========================

Cette image [Docker][docker] permet de gérer sur Kyle les dépôts Git anciennent sur Cartman.
Les dépôts et la configuration de gitolite et cgit sont dans le répertoire de l'utilisateur gitosis. Ce répertoire est prévu pour être "bindé" dans le conteneur au lancement. 

## Lancement

Pour construire l'image :

    $ docker build -t gitolite-cgit-cds:v10 .

Si besoin, avec proxy :

    $ docker build --build-arg HTTP_PROXY=http://10.100.4.178:3128 -t gitolite-cgit-cds:v10 .

Si on souhaite utiliser cette image en dehors de l'interface graphique Docker du NAS : 

COMPLETER ICI AVEC LA SECTION "Gitolite au premier lancement"

Avec un bindmount :
    $ docker run --name git-test -dit -p 8880:80 -p 2222:22 --volume /opt/git-home-on-host:/home/git  gitolite-cgit-cds:latest
    
Avec un volume interne Docker (option par défaut) : 
    $ docker run --name git-test -dit -p 8880:80 -p 2222:22 gitolite-cgit-cds:latest
    
Pour spécifier un nom de conteneur :
    $ docker run --name git-test -dit -p 8880:80 -p 2222:22 -v git-data:/home/git gitolite-cgit-cds:latest

Pour rentrer dans le conteneur :

    $ docker exec -ti git-test sh
    
On peut vérifier que les processus `sshd` et `httpd` tournent bien :

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
   

## Relancer un nouveau conteneur avec les données déjà existantes

Pour un volume interne Docker anonyme après avoir récupérer son nom par `docker volume ls` :

    $ sudo docker run --name git-test -dit -p 8880:80 -p 2222:22 -v 23bbae1624415494ddb345ad13777f7de3a248ac57fd84e6e24c5083f9835deb:/home/git gitolite-cgit-cds:latest
    
    
## Configurer Gitolite au premier lancement

### A l'intérieur de conteneur :

    $ docker exec -ti git-test sh
    $ gitolite setup -pk /tmp/admin.pub (la clé publique de l'administrateur doit avoir été préalablement envoyée dans le conteneur)
    $ chmod -R 755 repositories/

La sortie doit ressembler à ça :

    > Initialized empty Git repository in /home/git/repositories/gitolite-admin.git/
    > Initialized empty Git repository in /home/git/repositories/testing.git/
    > WARNING: /home/git/.ssh missing; creating a new one
    >     (this is normal on a brand new install)
    > WARNING: /home/git/.ssh/authorized_keys missing; creating a new one
    >     (this is normal on a brand new install)
    
### Au lancement du conteneur 

On utilise le paramètre `--rm` afin de détruire le conteneur sitôt l'exécution du script d'entrée terminée (`true` est une commande qui retourne immédiatement).
Ce premier lancement va créer les clés SSH du serveur et effectuer la configuration initiale de Gitolite à partir de la clé publique fournie.

Le volume interne nommé est passé en argument lors du lancement définitif. 

    $ docker run --rm --name git-test -dit -v git-data:/home/git -e SSH_KEY="$(cat /home/greg/.ssh/id_rsa.pub)" gitolite-cgit-cds:v20
    
La configuration est initialisée dans le volume qu'il suffit ensuite de reconncter. Et cette fois les ports doivent être renseignés :

    $ docker run --name git-test -dit -v git-data:/home/git -p 8880:80 -p 2222:22 gitolite-cgit-cds:v20

## Lancement

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
    

## Ajout des dépôts existants

Attention, cette méthode supprimer les hook d'update !

1- Se connecter au conteneur

2- Copier l'archive des dépôts : uniquement des bare repositories (sans copie de travail) se terminant par ".git" :

    $ scp greg@172.17.0.1:/opt/vm/repos/cartman-gitosis-repo.tgz /tmp/

3- Décompresser l'archive dans le répertoire des dépôts de Gitolite :

    $ cd /home/git/repositories
    $ tar -xf /tmp/cartman-gitosis-repo.tgz

4- Régler les permissions :

    $ chown -R git:git *
    $ chmod -R 755 *
    
5- Exécuter les commandes d'admin Gitolite (voir documentation pour plus de détails)

    $ su git
    $ cd
    $ gitolite compile
    $ gitolite setup --hooks-only
    $ gitolite trigger POST_COMPILE
    
6- Clôner le dépot d'administration Gitosis afin d'y modifier en conséquence le fichier `gitolite.conf` et ajouter les clés des utilisateurs dans `keydir`

7- Commiter et pousser les changements.



## Utilisation de Gitolite 

Gitolite tout comme son ancètre Gitosis identifie les utilisateurs par la clés publique qu'ils utilisent. Ces utilisateurs n'ont donc aucun rapport avec ceux connus du système. Toutes connexions vers Gitolite se feront ainsi avec l'utilisateur `git` associé à votre clé publique.

## Configurer le proxy pour Git

    $ git config --global http.https://github.com.proxy http://10.100.4.178:3128
    $ git config --global http.https://github.com.sslVerify false
    
Pour ajouter une entrée dans le fichier `~\.gitconfig`.

## Voir aussi

* [Image de base utilisée (httpd 2.4) ](https:https://hub.docker.com/_/httpd)
* [Exemple d'image gitolite](http://github.com/sitaramc/gitolite#adding-users-and-repos)
* [Exemple d'image cgit](https://github.com/invokr/docker-cgit)
* [Documentation officielle Gitolite](https://gitolite.com/gitolite/basic-admin.html)

[docker]: https://www.docker.com/
