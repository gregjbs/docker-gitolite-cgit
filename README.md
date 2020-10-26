Image docker Gitolite/cgit
=========================

Cette image [Docker][docker] permet de gérer sur Kyle les dépôts Git anciennent sur Cartman.
Les dépôts et la configuration de gitolite et cgit sont dans le répertoire de l'utilisateur gitosis. Ce répertoire est prévu pour être "bindé" dans le conteneur au lancement. 

## Lancement

Pour construire l'image :

    $ docker build -t gitosis-cds:v31 .

Si on souhaite utiliser cette image en dehors de l'interface graphique Docker du NAS : 

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

A l'intérieur de conteneur :

    $ docker exec -ti git-test sh
    $ gitolite setup -pk /tmp/admin.pub (la clé publique de l'administrateur doit avoir été préalablement envoyée dans le conteneur)
    $ chmod -R 755 repositories/

La sortie doit ressembler à ça :

    
Au lancement du conteneur (`true` à la fin stoppera le conteneur immédiatement à la sortie du script d'entrée) : 

    $ docker run --rm -e SSH_KEY="$(cat ~/.ssh/id_rsa.pub)" -v git-data:/home/git gitolite-cgit-cds:latest true

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


## Voir aussi

* [Image de base utilisée (httpd 2.4) ](https:https://hub.docker.com/_/httpd)
* [Exemple d'image gitolite](http://github.com/sitaramc/gitolite#adding-users-and-repos)
* [Exemple d'image cgit](https://github.com/invokr/docker-cgit)

[docker]: https://www.docker.com/
