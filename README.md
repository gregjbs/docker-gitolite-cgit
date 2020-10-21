Image docker Gitolite/cgit
=========================

Cette image [Docker][docker] permet de gérer sur Kyle les dépôts Git anciennent sur Cartman.
Les dépôts et la configuration de gitolite et cgit sont dans le répertoire de l'utilisateur gitosis. Ce répertoire est prévu pour être "bindé" dans le conteneur au lancement. 

## Lancement

Pour construire l'image :

    $ docker build -t gitosis-cds:v31 .

Si on souhaite utiliser cette image en dehors du NAS : 

    $ docker run --name git-test -dit -p 8880:80 -p 2222:22 --volume /opt/gitosis-home:/home/gitosis  gitosis-cds:latest
    
Pour rentrer dans le conteneur une fois lancé :

    $ docker exec -ti git-test sh

## Voir aussi

* [Image de base utilisée (httpd 2.4) ](https:https://hub.docker.com/_/httpd)

[docker]: https://www.docker.com/
