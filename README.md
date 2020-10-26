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

Pour rentrer dans le conteneur :

    $ docker exec -ti git-test sh
   

## Relancer un nouveau conteneur avec les données déjà existantes

Pour un volume interne Docker anonyme après avoir récupérer son nom par `docker volume ls` :

    $ sudo docker run --name git-test -dit -p 8880:80 -p 2222:22 -v 23bbae1624415494ddb345ad13777f7de3a248ac57fd84e6e24c5083f9835deb:/home/git gitolite-cgit-cds:v07
    
    
## Configurer Gitolite au premier lancement

A l'intérieur de conteneur :

    $ docker exec -ti git-test sh
    $ gitolite setup -pk /tmp/admin.pub (la clé publique de l'administrateur doit avoir été préalablement envoyée dans le conteneur)
    $ chmod -R 755 repositories/
    



## Voir aussi

* [Image de base utilisée (httpd 2.4) ](https:https://hub.docker.com/_/httpd)

[docker]: https://www.docker.com/
