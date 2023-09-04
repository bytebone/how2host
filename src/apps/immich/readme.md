---
# author: giga
category: [Privacy, Media]
icon: file-media
---

## Prerequisites

[!ref icon="check-circle" text="Complete First Steps"](/first-steps/1-vps-setup.md)

## What is Immich

Immich is a self-hosted, open-source photo and video backup solution.

## Installing Immich

[!ref Official Docs](https://immich.app/docs/overview/introduction)

To start, create a new directory for the Immich container files (e.g. `mkdir /home/docker/immich`), start editing with `nano compose.yml` and paste the following contents:

```yaml
version: "3.8"

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    command: [ "start.sh", "immich" ]
    volumes:
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
    env_file:
      - .env
    depends_on:
      - redis
      - database
    restart: always

  immich-microservices:
    container_name: immich_microservices
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    # extends:
    #   file: hwaccel.yml
    #   service: hwaccel
    command: [ "start.sh", "microservices" ]
    volumes:
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
    env_file:
      - .env
    depends_on:
      - redis
      - database
    restart: always

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
    volumes:
      - model-cache:/cache
    env_file:
      - .env
    restart: always

  immich-web:
    container_name: immich_web
    image: ghcr.io/immich-app/immich-web:${IMMICH_VERSION:-release}
    env_file:
      - .env
    restart: always

  redis:
    container_name: immich_redis
    image: redis:6.2-alpine@sha256:70a7a5b641117670beae0d80658430853896b5ef269ccf00d1827427e3263fa3
    restart: always

  database:
    container_name: immich_postgres
    image: postgres:14-alpine@sha256:28407a9961e76f2d285dc6991e8e48893503cc3836a4755bbc2d40bcc272a441
    env_file:
      - .env
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: always

  immich-proxy:
    container_name: immich_proxy
    image: ghcr.io/immich-app/immich-proxy:${IMMICH_VERSION:-release}
    environment:
      # Make sure these values get passed through from the env file
      - IMMICH_SERVER_URL
      - IMMICH_WEB_URL
    depends_on:
      - immich-server
      - immich-web
    restart: always

volumes:
  pgdata:
  model-cache:
  tsdata:
```

## Environment Variables

As mentioned, we also need an environment variables file. You can create it with the following command:

```bash
nano /home/docker/immich/.env
```

Then, paste the following contents:

```bash
# Database
DB_HOSTNAME=immich_postgres
DB_USERNAME=postgres
DB_PASSWORD=<database_password>
DB_DATABASE_NAME=immichdb

# Redis
REDIS_HOSTNAME=immich_redis

# Upload File Config
UPLOAD_LOCATION=./upload

# Web panel endpoint
VITE_SERVER_ENDPOINT=https://immich.<domain>/api

# Disable TypeSense
TYPESENSE_ENABLED=false
```

!!!
Immich by default uses the upload location `./upload`. Be aware that all data will be stored in that specific folder. If you **don't** have enough storage, pick another location.
!!!

Don't forget to replace the `<database_password>` with your own **unique** password!

!!!danger Web Panel
The `VITE_SERVER_ENDPOINT` environment variable defines where the Web Panel will be located (e.g `https://immich.example.com/api`). Make sure there is **no** foward slash at the end and that `/api` is kept.
!!!

## Running Immich

You can now run `docker-compose up -d` to install and run the Immich container.

Once the containers are up and running, you can access Immich by navigating to `https://immich.<yourdomain>` in your web browser. You'll be prompted to create an admin account and set up your media library.

## Closing words

That's it! You now have a fully functional Immich instance running on your server.
