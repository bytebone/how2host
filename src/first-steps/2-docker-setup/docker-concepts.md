---
# author: bytebone
---

[!ref Official Docs](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

# Docker Concepts

Docker is a containerization software that allows you to run many different programs and servers in isolated environments, where they will always have all their required dependencies installed without you needing them on your host system. Different apps are cut off from each other, unless you manually connect them.

## Images

A *Docker Image* is the actual software image, stored on your hard drive, that will be used to run the app you're setting up. It contains all the compiled code, as well as the OS requirements that the image developer included. The size of Docker images can range from a couple of megabytes to over a gigabyte.

### Important commands

- `docker pull <image>` will download the image from the repository
- `docker image ls` will list all images that you have stored on your drive
- `docker image rm <image>` will delete the specified image from your storage
    - this command will fail if a container is still using that image, or if another image depends on that image

## Containers

*Containers* are the result of running an app from its image. This container usually has a startup command that is executed whenever the container is started, for example to run a webserver or serve an app on a specific port. Data in a running container is **ephemeral**, meaning that any changes inside it will be lost once the container is deleted. To persist data in a container, Docker makes use of [Volumes](#volumes).

### Important commands

- `docker run <image>` starts a container based on the specified image
- `docker stop <container>` stops the specified container
- `docker container ls` lists all running containers
    - add `-a` to list running and stopped containers
- `docker container rm <container>` deletes the specified container

## Volumes

Since all data in a container is deleted with the container itself, *Images* are used to persist data between separate instances of an image. This is important for any data you don't want to lose when you update images or perform maintenance on an app. There are two ways to use volumes: bind mounts and *Docker volumes*. 

### Bind mount

A bind mount takes a folder on your storage and directly mounts it into the container. This way, you can add specific system files or folders into a container, or store the appdata right beside your configuration files. If you're using bind mnounts, it is your job to ensure that the folders you're mounting are accessible by the app that is supposed to read from them. This usually involves researching what user the app runs as and a bit of `chown` and `chmod` to grant the app access to your host folder.

### Docker volume

Docker volumes are an abstraction of regular mounted folders. They are also stored on your storage, specifically at `/var/lib/docker/volumes`, but Docker automatically manages all permissions for them, as well as keeping track which app made which volume. This means that you can very quickly set up apps and never have to worry about permissions, but it can make extracting the data and moving it to a new server more work, since Docker tracks changes in volumes and will be confused about volumes that it has not created itself.

!!!
Using Volumes is recommended for anyone who is just getting started with Docker. They are fast and easy to use, and do not require maintenance. Once you're more comfortable with the inner workings of Docker, you can always manually move the data into bind mounts.
!!!

### Important commands

- `docker volume create <name>` creates a new volume
- `docker volume ls` will list all volumes
- `docker volume rm <name>` will delete the specified volume

## Networks

*Networks* are crucial to understand and use when running larger applications that split their work across multiple smaller images. They allow you set up walled gardens per app, limiting which containers can communicate with one another.

Many apps include every required service in their base image, and do not need companion services to function. If this is the case for the app you're setting up, you usually don't need to worry about networking. 

As soon as an app requires more than one container, you should create a separate network for these services to communicate within. 

Docker containers are, by default, able to network through your host, allowing them to communicate with other devices in your network. This is not as relevant when using a VPS, which is already isolated, but becomes more important when hosting in your home.  
If you want to completely block off containers from external networking, you can create special *internal networks*. Any image in this network is cut off from the host and therefor the external internet, and can only communicate with other containers via Docker networks.

### Important commands

- `docker network create <name>` creates a new regular network
    - use `create --internal` to create an internal network instead
- `docker network ls` lists all networks
- `docker network rm <name>` deletes the specified network
    - this command will fail if there are still containers in that network

## Docker compose

<!-- add a link here -->
[!ref Docker compose specification]()

Docker compose is a plugin for Docker that allows you to use *compose files* to define one or multiple containers in one file. Compared to using the `docker run` command, this allows you to store all the information required to run your images in a simple, human-readable script, which makes it a lot easier to manage your containers in the long run.

Any guide on this site makes use of Docker compose. The files are usually called `compose.yml`, and are written in a simple YAML syntax. Any argument that exists for `docker run` has a counterpart in docker compose. And if an app you want to run only offers a `docker run` command, there are great web tools that translate this into a compose file. 

### Typical compose file layout

!!!
This example does not make realistic sense, since Caddy does not require a database and the paths for volumes are imaginary. Use this only to understand the structure of a compose file, not to actually run the services
!!!

```yml compose.yml
service:
    app: # this is the docker internal service name, it can be whatever you deem practical
        image: caddy/caddy:latest # image specification, made up of <owner>/<image-name>:<version>
        container_name: service-app # if you dont name the container here, it will be named automatically
        restart: unless-stopped
        volumes:
        # volumes are always specified as <location on host>:<location in container>
            - ./folder:/data # bind mount with a host path relative to the location of the compose file
            - /usr/bin/ffmpeg:/usr/bin/ffmpeg # bind mount with an absolute host path
            - data:/other-data # volume mount. note that this volume has to be defined in the volume section below
        networks:
            - reverse-proxy
            - internal

    db:
        image: postgres:15 # some very important images do not have a maintainer
        container_name: service-db
        restart: unless-stopped
        volumes:
            - other-volume: /var/lib/postgresql/
        networks:
        # since the database should only be accessibly by its accompanied app, 
        # we create a network only for internal communications of this service
            - internal

volumes:
# you only need to define volumes, not bind mounts
    data:
    # youre able to mount volumes that have not been created by this compose file,
    # but they need to be marked as external
    other-volume:
        external: true

networks:
# same thing as with volumes: all networks you want to use in this compose file need to be listed here.
    internal:
        # this makes the network fully blocked-off from external networking
        # any container that's only in internal networks will not be able to access the internet at all
        internal: true
    # networks not managed by this compose file need to be marked as external. 
    reverse-proxy:
        external: true
```

Every compose file has a *service name*. This name is usually taken from the name of the folder containing your `compose.yml`. When you create networks and volumes in your compose file, their names get prefixed with the service name. An example:
- You're setting up Vaultwarden. You're `compose.yml` is in `/home/docker/vaultwarden/`
- Taken from the folder name, Docker assumes the service name as `vaultwarden`
- If you create a network `internal` in this compose file, it will actually be called `vaultwarden-internal`
- Same goes for volumes: a volume called `data` in your compose file will actually be called `vaultwarden-data`

Take this into account when defining names __in your compose files__. You don't need to prefix them in there, and can use the same generic names for each of your apps. The more you use patterns for naming your components, the easier it will be to maintain a lot of services at once. 

## Docker networking

Lastly, if you're running an app with multiple services, how do you actually make them talk to one another? Docker makes this incredibly easy by allowing you to use the container and service names **instead of IP addresses**. Docker also allows apps to connect on specific ports **without having to expose them on the host**. 

To connect an app to its other services, you usually use configuration files or environmental variables. This depends on the app and is usually specified in its documentation. In general, you can always use **the container name** you specified in your compose file as the address: `http://vaultwarden-db:5432`. 

Never use the IP addresses assigned to containers by Docker. By default, they are not static and will change when recreating the container, forcing you to reconfigure your apps. There is no benefit in using IPs over your container names.