# mfg.partkeepr

Partkeepr is an inventory management system. This repository contains the code required to wrap it
up in a docker image.

## Deployment
Run something like:
```
$ make build  # Build docker image
$ make tag # Tag docker image with git short hash
$ make push # Push docker image to aws
$ make deploy-staging # Deploy docker image to staging environment
$ make deploy-production # Deploy docker image to production environment
```
After deployment, you'll need to run through the setup wizard located at `/setup` once to migrate
the database and set up an initial user to log in with.
1. First, run `docker exec -it <container id> chmod -R 777 /var/www/html`, as this is required for
   the setup process to complete.
2. Then, visit `/setup`
3. To get the auth key, run `docker exec -it <container id> cat app/authkey.php`

## Debugging
The container takes ages to start up. So, if you're getting a 410 back or a 503, it's probably
because either the container hasn't started (the 410) or the container hasn't finished booting /
passed its health check (the 503).

Tail the Apache logs:
```
$ docker logs -f <container id>
```

Take a look at the Partkeepr logs:
```
$ docker exec -it <container id> cat app/logs/partkeepr.log
```

## Bugs / helpful github issues
- Partkeepr only supports MariaDb <= 10.x.x: https://github.com/partkeepr/PartKeepr/issues/916
- Assets weren't being loaded when the container started up again, this ticket gave me some hints: https://github.com/partkeepr/PartKeepr/issues/949
  - I ended up adding a bunch of commands into the `docker-php-entrypoint` that warm up the cache /
    export assets prior to running, since partkeepr isn't meant to be run in a containerized
    environment.
