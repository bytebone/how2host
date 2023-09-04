---
# author: giga
category: [Privacy, Media]
icon: device-camera-video 
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
      - typesense
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
      - typesense
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

  typesense:
    container_name: immich_typesense
    image: typesense/typesense:0.24.1@sha256:9bcff2b829f12074426ca044b56160ca9d777a0c488303469143dd9f8259d4dd
    environment:
      - TYPESENSE_API_KEY=${TYPESENSE_API_KEY}
      - TYPESENSE_DATA_DIR=/data
      # remove this to get debug messages
      - GLOG_minloglevel=1
    volumes:
      - tsdata:/data
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
    ports:
      - 2283:8080
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
DB_HOSTNAME=immich-database-test
DB_USERNAME=postgres
DB_PASSWORD=<database_password>
DB_DATABASE_NAME=immichdb

# Redis
REDIS_HOSTNAME=immich-redis-test

# Upload File Config
UPLOAD_LOCATION=./upload

# WEB
VITE_SERVER_ENDPOINT=http://localhost:2283/api

TYPESENSE_ENABLED=false
```

Don't forget to replace the `<database_password>` with your own **unique** password!

## Running Immich

You can now run `docker-compose up -d` to install and run the Immich container.

Once the containers are up and running, you can access Immich by navigating to `https://<your_domain>:2283` in your web browser. You'll be prompted to create an admin account and set up your media library.

## Closing words

That's it! You now have a fully functional Immich instance running on your server.
