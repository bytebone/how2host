---
# author: rainer
order: -2
---

# Docker Setup 

[!ref Official Docs](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

## Setting up Docker and Docker Compose

This step is fairly simple. If you're not already, connect to your server via SSH. We're now going to run a couple of commands:

Installing some needed components

```
$ sudo apt-get update
$ sudo apt-get install ca-certificates curl gnupg
```

Installing the Docker repository

```	
$ sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

$ echo "deb [arch="$(dpkg --print-architecture)" \
signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Installing Docker & Docker Compose

```
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Checking both have installed properly

```
$ docker -v
$ docker compose version
```

If these final commands go through without errors, returning some version number, everything has worked perfectly.