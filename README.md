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
Le volume interne nommé est passé en argument. 

    $ docker run --name git-test -dit -v git-data:/home/git -e SSH_KEY="$(cat /home/greg/.ssh/id_rsa.pub)" gitolite-cgit-cds:v10
    
La configuration est initialisée dans le volume qu'il suffit ensuite de reconncter. Et cette fois les ports doivent être renseignés :

    $ docker run --name git-test -dit -v git-data:/home/git -p 8880:80 -p 2222:22 gitolite-cgit-cds:v10

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

[docker]: https://www.docker.com/
