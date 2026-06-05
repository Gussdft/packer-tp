# ci-cd

## Getting started

Ce projet ne fait que réagir à une requête GET sur la route /auth/:secret.  
Si le secret est sous la forme `secret-<SECRET>` et qu'il correspond au secret contenu dans la variable d'environnement `PASSPHRASE` ou par défaut 'mysecretphrase'.

La route devrait donc renvoyer 200 OK avec la requête suivante :  
GET http://localhost:3000/auth/secret-mysecretphrase
