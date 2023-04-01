# The entire guide how to install and secure Vaultwarden

## Chapters
1. [Getting a Domain](#1-getting-a-domain)
2. [Getting](#21-getting-a-vps) & [Securing a VPS](#22-securing-your-vps)
3. [Connecting Domain to VPS with Cloudflare](#3-connecting-your-domain-and-vps-with-cloudflare)
4. [Setting up Docker and Docker Compose](#4-setting-up-docker-and-docker-compose)
5. [Installing Nginx](#5-installing-nginx-proxy-manager)
6. [Installing and exposing Vaultwarden](#6-installing-vaultwarden)
7. [Securing Vaultwarden with CrowdSec](#7-securing-vaultwarden-with-crowdsec)
8. [Securing Vaultwarden Admin Panel](#8-securing-your-vaultwarden-admin-panel)
9. [Setting up Vaultwarden backups](#9-setting-up-vaultwarden-backups)
10. [Closing thoughts](#10-closing-thoughts)

## Prerequisites
1. Basic knowledge in Terminal and Linux CLI usage
2. Very basic knowledge of networking
3. 5-15 $ a year for the domain name
4. 5-10 $ a month for the server
5. You will create multiple accounts, for buying your domain, renting your server, and securing your VPS with Cloudflare

## Introduction

Trying to set up a VPS and installing the password management server "Vaultwarden" on it is no easy task. Every app has their own independant documentation, making it hard to understand how they should be connected to each other, and the different components have been on the market for many years, causing many popular forum threads to contain horribly out-of-date information on how to handle Docker, containers, ports and all the other parts of this process.

To finally fill this gap, this guide aims to cover **the entire journey** from buying your VPS until the very last bit of hardening the installation, and to be the only ressource you need to get everything set up and secure.

I've tried my hardest to make this guide as unopinionated and informative as possible. But if you want to read more about each of the topics (and you should!), I've linked the official documentations per section under the headline. That being said, let's get right into the nitty gritty!

## 1. Getting a Domain

In order to properly use Vaultwarden (or any other services you'd be hosting on your server), you need a domain name. This can be pretty much anything you want that hasn't been used yet. There are countless vendors for domain names, which is why I like to use [TLD-List](https://tld-list.com/) as a starting point. You'll probably want to set the filters to something like

- **Cheapest Register Price:** 0-20
- **Character Count:** 2-6
- **Domain Level:** Top-level domains
- **WHOIS Privacy:** Supported
- **TLD Phase:** In General Availability

Now, you can brainstorm some ideas how you could call your domain, enter it into the search box up top, and see both what that domain name would cost with different TLDs, as well as if they're still available. **Keep in mind** that not only the registering price matters - you'll have to renew the domain at some point, usually after a year. Don't fall for a cheap registrar price that renews at 3-10x that! 

**Additionally**, when you found a TLD you like, click on its' label to see the list of available registrars. You should look for one that supports both **free WHOIS privacy** and **DNS settings**. While the former is only very much recommended, the latter is crucial!

Once you found something you like, go through the purchasing process as with any online purchase.

## 2.1 Getting a VPS

This is a step with which I can hardly help you. There are countless VPS providers with varying price and quality. Which one you should choose depends on your region of living and your budget. Personally, I've been happy with [Hetzner](https://www.hetzner.com/cloud), who offer hosting in Europe and America. Others that I haven't tried, but who are big and known games in the server space, are [Linode](https://www.linode.com/products/shared/), [Hostinger](https://www.hostinger.com/vps-hosting), [Digital Ocean](https://www.digitalocean.com/solutions/vps-hosting) and [OVHCloud](https://us.ovhcloud.com/vps/), with many more options when spending some time on Google and in comparisons / benchmarks of different providers in your country. You can also check out [LowEndTalk](https://lowendtalk.com/), which is an online forum for affordable hosting solutions. 

The only thing you should really be looking for is a server that supports an Ubuntu image out of the box. I've yet to see a VPS provider that doesn't, but still look out for it. Regarding specs, a small spec server is more than enough. I've been running my applications on **2 shared cores, 2GB of RAM and 40GB of storage** without problems. You can obviously go higher if you have the cash to do so.

After you've found a provider you're confident in and have purchased the server, you should be presented with an **IP address, a username and a root password**. How you get these differs between providers; sometimes they are laid out in the server dashboard, sometimes you receive them via e-mail. 

Once you have these credentials on hand, open the terminal of your choice (*CMD* on Windows, *Terminal* on Mac, Linux users know it themselves) and enter the following command:

    ssh root:<root password>@<ip address>
   
Replace `<root password>` and `<ip address>` with their respective strings from your server dashboard. After pressing enter and a short pause, you should be connected to your server.

> Should this fail, use only `ssh root@<ip address>` and enter the root password when prompted.

## 2.2 Securing your VPS

We don't want your VPS to be open to the internet or easy to find, do we? Let's change some basic settings to make sure the server is tough to find and even tougher to hack.

### Generating and installing SSH keys
> This step assumes you've never set up SSH keys before. If you have, make sure to not overwrite your existing keys!

As our first step, we're going to **generate and install** an SSH certificate. This is a much safer authentification method compared to passwords, and you won't even have to enter anything when connecting to your server. 
To start, you're gonna disconnect from the server with the `exit` command. Now, back in your local machines' terminal, run `ssh-keygen -b 4096`. When asked for a filepath, press enter **if you don't already have SSH keys with the default name**, or feel free to enter another save location. When asked for a passphrase, simply press enter twice, entering nothing.
If everything went fine, the command will display the output paths for two files, along some other unrequired details.

Now, run the command `ssh-copy-id -f .ssh/id_rsa.pub root@<ip address>`, press enter, paste the root password once more, and the command should exit without errors. Should you have used another save location or file name when generating the SSH key, use that in place of `.ssh/id_rsa.pub`. In any case, use the file ending in `.pub`, **not the file without a file extension!**

### Securing the SSH access
[Assistance](https://linuxize.com/post/how-to-change-ssh-port-in-linux/)

Now, we're going to lock down your server to make finding it much harder for bots scouring the internet. Connect to your server with the same SSH command as before, and enter the root password if prompted.
Once you're connected, run `nano /etc/ssh/sshd_config`, which will open a long text file. Here, find the following lines, remove the leading # and change the values as written:

    Port <any number between 1024 and 65536>
    PermitRootLogin prohibit-password
    PasswordAuthentication no
    PermitEmptyPasswords no
    X11Forwarding no

Make sure that these lines only exist once in the config file - I've seen them duplicated at the end of the file for some server hosters. Should that be the case, delete these duplicated lines using `CTRL+Shift+K`. Once you've changed the settings, press `CTRL+X` followed by `y` to save and exit. Then, run `systemctl restart ssh` to apply the changes. 
To verify that SSH daemon is now listening on the new port, run `lsof -Pni | grep sshd`, which should return something like this:

    sshd    24167    root  3u  IPv4  99527151   0t0  TCP *:4334 (LISTEN)
    sshd    24167    root  4u  IPv6  99527153   0t0  TCP *:4334 (LISTEN)
    sshd    29370    root  4u  IPv4  10998432   0t0  TCP 172.0.0.1:4334->56.223.57.86:51434 (ESTABLISHED)

Where `4334` would be the port you've specified.

To finish this this section, disconnect from the server once more, returning to your local terminal, and run the command `nano .ssh/config`. 
> This command will not work on Windows, and I don't know which command will. Feel free to make a PR adding this info.

An empty text editor should open, in which you will paste the following text:

    Host <server name>
      HostName <ip address>
      User root
      Port <SSH port>
      IdentityFile ~/.ssh/id_rsa

Replace the <server name> with any memorable shorthand you want - you will use it to connect to the server in the future. Also enter the servers' IP address and the SSH port you've specified before, and make sure the SSH key location is correct. Once done, leave the editor with the same keybinds as before (`CTRL+Shift+X` followed by `y`). 

From now on, to connect to the server, all you need to enter is `ssh <server name>`! So, as an example, if you called the server "vps" in your config, you'd enter `ssh vps`, press enter, and connect in a matter of seconds, without ever needing a password.

## 3. Connecting your Domain and VPS with Cloudflare
[Official Docs](https://developers.cloudflare.com/learning-paths/get-started/#live_website)

To access your services with your domain name, we need to connect one to the other first. To help us do this **securely**, we'll make use of Cloudflare's DNS Proxy service, which will hide your server IP from anyone accessing your domain, increasing security by obfuscation. To start, go to https://dash.cloudflare.com/sign-up and create an account.

Once you're in the dashboard, click "Add Site", enter the domain name you've chosen before and select the free plan when prompted. On the next page, you should be confronted with the DNS entries on the domain - of which you probably have none. Should there be any A or AAAA entries, remove them, then add new ones, providing your servers IP address. 

- use A entries for IPv4 (123.456.78.9)
- use AAAA entries for IPv6 (2a02:81b4:c0:27:b227:9b:::)

For each IPv4 and IPv6, make two DNS entries - one using `@` as name, and one using `*`. This ensures that **every** request gets directed at your server, no matter what.

Once you're done, confirm and make note of the following page. You will now need to go to the provider where you've bought your domain name, and find the DNS settings panel. You're looking for the setting to change the **domains' nameservers**. Change them according to Cloudflares' instructions, and confirm on the Cloudflare page once you're done. This change can take some time to propagate. You'll need a bit of patience until it comes through, but Cloudflare will send you an e-mail once it's completed.

While this is processing, you can click through the different menus of the page and get an overview of all the things you can change. Feel free to change what you're confident you understand, or read along on the next section.

## 4. Setting up Docker and Docker Compose
[Official Docs](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

This step is fairly simple. If you're not already, connect to your server via SSH. We're now going to run a couple of commands:

Installing some needed components

    $ sudo apt-get update
	$ sudo apt-get install ca-certificates curl gnupg

Installing the Docker repository
	
	$ sudo mkdir -m 0755 -p /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

	$ echo "deb [arch="$(dpkg --print-architecture)" \
	signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

Installing Docker & Docker Compose

	$ sudo apt-get update
	$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

Checking both have installed properly

	$ docker -v
	$ docker compose version

If these final commands go through without errors, returning some version number, everything has worked perfectly.

## 5. Installing Nginx Proxy Manager
[Official Docs](https://nginxproxymanager.com/guide/#quick-setup)

Nginx is a reverse proxy, which we will use to direct traffic on your domain name to the different services on your server. There are different options to fulfill this task, such as [bare nginx](https://www.nginx.com/blog/deploying-nginx-nginx-plus-docker/), [traefik](https://doc.traefik.io/traefik/getting-started/quick-start/) and [caddy](). You're free to explore these other options, but they won't be covered in this guide.

One thing that many people don't properly set up is their ports. No matter which app you're going to set up in the future, their documentation will ask you to open ports on your hosts. This means that the services are easily accessible to anyone using a combination of your servers IP and the specified port of the host. **Doing this is a big security risk and defies any use of a reverse proxy!** It is important to understand that you do not need to open any ports to make a service accessible to Nginx, and therefor the open internet. I'll point this out again in a moment.

To get started with the Nginx setup, create a new folder at any location you please. As an example, we're going to use `mkdir -p /home/docker/nginx`, followed by `cd /home/docker/nginx`. Now, run `nano compose.yml` and paste the following code:

	services:
	  nginx:
	    image: jc21/nginx-proxy-manager:latest
	    container_name: nginx 
	    restart: always
	    ports:
	      - 80:80
	      - 81:81
	      - 443:443
	    environment:
	      DB_MYSQL_HOST: db
	      DB_MYSQL_PORT: 3306
	      DB_MYSQL_USER: npm
	      DB_MYSQL_PASSWORD: <random string #1>
	      DB_MYSQL_NAME: npm
	    volumes:
	      - data:/data
	      - data:/etc/letsencrypt
	    depends_on:
	      - db

	  db:
	    image: mariadb
	    container_name: nginx-db
	    restart: always
	    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW --innodb-file-per-table=1 --skip-innodb-read-only-compressed
	    volumes:
	      - db:/var/lib/mysql
	    environment:
	      - MYSQL_ROOT_PASSWORD=<random string #2>
	      - MYSQL_PASSWORD=<random string #1>
	      - MYSQL_DATABASE=npm
	      - MYSQL_USER=npm

	networks:
	  default:

	volumes:
	  db:
	  data:

 A short explanation of this script:
 
 - The `services` section defines both the actual Nginx app, as well as the database used to store data.
   - You need to generate two random strings as passwords, and put them in the appropriate spots. You can do that with `openssl rand -base64 20`. Make sure that the password matches in the two places using `<random string #1>`! 
   - For now, we will expose both port 80 and 81, which are unsecure ports that we will close down in a second.
   - The `container_name` property manually defines the name, since the auto generated names are long and ugly. We will need to enter this into the Nginx interface in a minute!
 - The `networks` section defines the docker network that Nginx will sit in. In the future, any new container you want accessible from the internet needs to be in this network.
 - The `volumes` section defines two volumes, which are storage locations for persistent data, since a container will be deleted with all its included data whenever you stop or restart it.

As you've done before, exit nano and save your changes. Once you've left nano, run `docker compose up` to download and start Nginx with its components. Once the logs mention a successful startup, open your browser and enter into the address bar `<your server ip>:81`. This should bring up the NPM login screen. The login credentials are `admin@example.com` and `changeme` as the password. You will be prompted to create a new password immediately.

Once logged in, navigate to the green "Proxy Hosts" section, click "Add Proxy Host" in the top right, and enter the following details:

- **Domain Names:** proxy.your.domain (replace `your.domain` with your actual domain)
- **Forward Hostname:** nginx (this is the name of the container in docker)
- **Port:** 81
- **Toggle Common Exploits:** On

Press Save, then click on the domain name in your list. The URL will open in a new tab and should load you right into the NPM interface. **This should have been the last time you ever access the server with its IP instead of a domain.** 

### Enforcing encryption between your server and Cloudflare
[Official Docs](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/)

In the current setup, your server sends unencrypted content to the Cloudflare proxy, which then encrypts it locally and forwards it to the person accessing your website. This is bad, because anyone could intercept, read and modify the data before it reaches Cloudflare, as well as read all the traffic sent back to your server. 

To lock this down, go to the `Cloudflare Dashboard > Your Website > SSL/TLS > Origin Server`, click on `Create Certificate`, confirm that the hostnames are both `*.your.domain` and `your.domain`, decrease the validity to a more sensible 2 years if desired, and confirm. After a short pause, you will get two text boxes with random-looking strings in them. You need to copy the contents of both and paste them into two files on your local machine. The content of `Private Key` should be saved into a file called `cert.key`, and the content of `Origin Certificate` into a file called `cert.pem`. You can do this with any text editor, even notepad. Just make sure the file extension matches!

Once you saved them, open your Nginx dashboard, switch to `SSL Certificates` and `Add SSL Certificate > Custom`. You cannot change the name later, so I recommend calling it `CF <your domain>`, in case you'll be hosting multiple domains from this server - this happens faster than you think! For the key, upload your `cert.key`, and for the certificate your `cert.pem`, and save the certificate.

Now, switch back to the Proxy Hosts tab. Edit your Nginx entry, change to the SSL Tab, and select your newly added certificate. Also, toggle the "Force SSL" switch - the others don't do much in your use case.

To finish this step, go back to your Cloudflare Dashboard, switch to `SSL/TLS > Overview`, and at the very top, set the encryption mode to `Full (Strict)`. This ensures that only traffic that has been encrypted with the specific certificate will be accepted by Cloudflare, providing maximum security for you and any other visitors of your pages.

If after this change, your Nginx dashboard still loads fine, you've done it. Since now, every little bit of traffic will be running over the encrypted port 443, we can close the other ports still opened by Nginx. So, go back into the terminal, where the Nginx container should still be running in the foregound. Press `CTRL+C` to quit it, then `nano compose.yml` to get back into the config file. Find and remove the two lines with which Nginx exposes the ports 80 and 81. Exit and save out of nano, then run `docker compose up -d` to start Nginx again, but this time in the background. Reload the Nginx website to make sure it's running and working, and run `lsof -Pni | grep docker` in your terminal to confirm that only port 443 is opened.

## Detour: Further securing the server

Now that we can securely access and manage the server with its domain name, we can lock it down even further to aggresively limit the connection possibilites to the bare minimum we need. In its current configuration, we will only access it by two means: 

1. Directly from our IP to the server IP, when using SSH 
2. Through the Cloudflare servers when accessing a website, over port 443.

This means that we can set up the server firewall to **only allow** connections to port 443 when they're coming from any of the Cloudflare IPs, and connections to the SSH port you set up at the start, coming from any IP. Every other connection attempt is not intended to be made, and should therefore be rejected.

To set this up, you'll need to either use your server providers firewall (if they have one), or the VPS integrated firewall. I can't write guides for every server provider, so refer to their docs for guidance. If the server provider doesn't have a separate firewall in front of your server, you can use firewalls such as `iptables` or `ufw` on your server directly, though `iptables` will be used for later steps anyways, so prefer that if possible. Writing a guide for this also goes beyond the (already large) scope of this guide, but [this RedHat guide](https://www.redhat.com/sysadmin/iptables) is a great point to start. You can find the Cloudflare IP Range [here](https://www.cloudflare.com/ips/).

Summarizing what rules you need to set up (in chronological order):

1. Allow **any IP** to access your custom SSH port
2. Allow **any IP from the Cloudflare IP List** to access port 443
3. Drop **every** other request
4. Outgoing traffic should not be limited

Be careful to read the iptables guide in its' entirety before starting, as you can very quickly lock yourself out of the system, which would force you to reinstall the entire server and **start from scratch!**

## 6. Installing Vaultwarden
[Official Docs](https://github.com/dani-garcia/vaultwarden/wiki)

You're coming along nicely, and are finally ready to actually install Vaultwarden. As you're getting more familiar with Linux navigation, Docker and nginx hosts, I'll be summarizing more and more from here on out.

To start, make a new directory for the Vaultwarden config: `mkdir /home/docker/vaultwarden` and open it for editing: `nano /home/docker/vaultwarden/compose.yml`. Paste the following contents:

	services:
	  vaultwarden:
	    image: vaultwarden/server:latest
	    restart: unless-stopped
	    container_name: vaultwarden-app
	    # user: 1123:1123
	    env_file: .env
	    volumes:
	      - data:/data
	    networks:
	      - nginx_default
	      - db

	  postgres:
	    image: postgres:14-alpine
	    restart: unless-stopped
	    container_name: vaultwarden-db
	    environment:
	      - POSTGRES_USER=vault
	      - POSTGRES_PASSWORD=<db_password>
	      - POSTGRES_DB=vaultwarden
	    networks:
	      - db
	    volumes:
	      - db:/var/lib/postgresql/data

	volumes:
	  data:
	    external: true
	  db:

	networks:
	  db:
	  nginx_default:
	    external: true

Again, some notes on this compose file:

- To make Vaultwarden accessible from the outside world, we need to add it to a network that Nginx is also in. To make it easy, we simply add it to the network that Nginx created on startup. Note that it's actually called differently than in the Nginx compose file, because docker prepends the project name when creating networks, volumes and unnamed containers.
	- To do this, we need to add the `external: true` property to the network when we define it at the end of the file. This specifies that the network does not belong to this project, but is an outside object.
- We've also specified a new line: `env_file: .env`. These files store "environment variables" that many containers use for customization.
- Vaultwarden uses a PostreSQL database to store all the data you provide it. This database **doesn't need to be** accessible from the outside world - it would be very problematic if it was. Therefor, we don't add it to the Nginx network. We create a separate network, just for the communication between Vaultwarden and the database. No other service that's not related to Vaultwarden should be in this network!
- In this compose file, I've specified the postgres release `14-alpine`. This will be updated in the future, to `15-alpine`, `16-alpine` and so on. Check the [official Docker repo](https://hub.docker.com/_/postgres) for the latest version and change this accordingly.

As mentioned, we also need an environment variables file. You can get it from the [official repo](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template), or use this direct command to download it right into your project folder: 

	curl -o /home/docker/vaultwarden/.env -L https://raw.githubusercontent.com/dani-garcia/vaultwarden/main/.env.template

Now, open the file `nano .env` and change the following lines:

- `DATABASE_URL` specifies the database connection. It should look like this: 
    `DATABASE_URL=postgresql://vault:<db_password>@vaultwarden-db:5432/vault`
    Use the <db_password> you've specified in the compose file!
- `WEBSOCKET_ENABLED=true`
- `DISABLE_ADMIN_TOKEN=true`
- `DOMAIN=https://vault.your.domain`
	- Obviously, set this to the domain you wanna access Vaultwarden on. 

That's pretty much it! You can now run `docker compose up -d && docker compose logs -f` to install and run the containers, and immediately jump into the logs of it all to see that it works fine. This allows you to quit out of the logs without shutting down the container later. 

Now, all that's left is to set up the host in Nginx. It's as easy as before: 

1. Open the Nginx interface, switch to `Proxy Hosts` and `Add new Host`
2. Enter the domain you've specified in the .env file, e.g. `vault.your.domain`
3. Enter `vaultwarden-app` as the hostname, and `80` as the port
	- You can confirm the port from the docker logs, it might also be `3000`
4. Enable both `Websockets Support` and `Block Common Exploits`
5. Choose your CF Certificate in the SSL tab and activate `Force SSL`
6. Lastly, under `Custom Locations`, add two entries:
	1. The first entry enables Websocket support
		- Location: `/notifications/hub`
		- Hostname: `vaultwarden-app`
		- Port: `3012`
		- Click the Cogwheel next to the Hostname and paste the following into the textbox:
			`proxy_set_header Upgrade $http_upgrade;`
			`proxy_set_header Connection "upgrade";`
	2. The second entry disables webhooks on a subdirectory
		- Location: `/notifications/hub/negotiate`
		- Hostname: `vaultwarden-app`
		- Port: `80` (or whatever port the app is running on in your case)

From this point onwards, you should be able to access Vaultwarden on the specified domain. You can watch the Docker logs for a bit while creating your account, to make sure there are no errors. 

## 7. Securing Vaultwarden with CrowdSec

Vaultwarden is already very secure. It brings its own rate limiter for login attempts to combat bruteforcing, and since you're behind the Cloudflare Proxy, you're also protected from DDoS and other attacks. There's barely anything left to do, but we can go one final step. Should someone find this service and decide to bruteforce your login, we can ban their entire IP to permit access to the entire server. This will take some setup, so stay with me here.

Many people would use Fail2Ban for this case, but I've found CrowdSec to be both easier to manage and especially monitor, and more efficient in its banning of offenders. Feel free to figure out Fail2Ban on your own if you so desire - this guide will cover CrowdSec.

### Setting up the Vaultwarden Admin Panel

Before we can do anything meaningful, we need to change an integral setting in the Vaultwarden Admin panel. To do this, open your Vaultwarden Website, then append `/admin` to the URL (e.g. `vault.your.domain/admin`). This should directly lead you to the unsecured admin panel - don't worry, we'll fix that at the end of the guide. For now, navigate into the `Advanced Settings` category and enter `CF-Connecting-IP` into the `Client IP header` field. This enables Vaultwarden to see the real IP addresses of people connecting to your instance, instead of the Cloudflare Proxys' IP. 

> While you're here, you can also change some other settings, like disabling new signups, or anything else you deem useful.

Save your changes with the button at the bottom, and close the tab. 
If you wanna control that this has worked, run `docker logs -f vaultwarden-app`, open the Vaultwarden page and log in. You should see your IP in the Docker logs. Should you not have made an account yet, you can also try logging in with fake credentials.

### Installing CrowdSec & Components
[Official Docs](https://docs.crowdsec.net/docs/getting_started/install_crowdsec)

Now get back to your terminal, and run the following commands, one by one:

	$ curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
	$ sudo apt install crowdsec
	$ sudo apt install crowdsec-firewall-bouncer-iptables
	$ cscli collections install Dominic-Wagner/vaultwarden

With these commands, you've installed CrowdSec, their firewall bouncer, and the Vaultwarden configuration. Now, we need to set these components up properly to enable them to communicate with each other.

First, run `nano /etc/crowdsec/acquis.yaml` to edit the **CrowdSec Acquisition File**, where we will add the Docker logs of the Vaultwarden container. Add the following text at the end of the file:

	---
	source: docker
	container_name:
		- vaultwarden-app
	labels:
		type: Vaultwarden
	---

If you set a different container name for your Vaultwarden container, change that accordingly here. The label on the other hand is required by the Vaultwarden Collection and has to be exactly like above.

To finish this step, run `systemctl reload crowdsec`. Open your Vaultwarden website once more, and log in with either real or fake credentials. Then, run `cscli metrics` in the terminal and confirm that `docker:vaultwarden-app` is listed as one of the data sources, with some lines read already.

### Configure Firewall Bouncer

Next, we're setting up the firewall bouncer. This again requires running a couple of commands. First, run `ip6tables -N DOCKER-USER` to add an IPv6 chain, then run both `iptables -L` and `ip6tables -L`, each time checking that a `Chain DOCKER-USER` does exist. 

Now, run `nano /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml` to change some things in the bouncer config:

- Change `disable_ipv6:` to `true`
- Uncomment `- DOCKER-USER` under `iptables_chains`
- Leave the rest unchanged

Save your edits and quit nano, then run `systemctl reload crowdsec-firewall-bouncer` to apply your changes. You can follow this up with `systemctl status crowdsec-firewall-bouncer` and make sure its both running and healthy. Finally, run `iptables -L DOCKER-USER` and `ip6tables -L DOCKER-USER`, each time checking that a `crowdsec-blacklists` rule has been applied. The name differs slightly between `ip` and `ip6`.

That's it. CrowdSec now runs in the background, monitoring your SSH logs as well as your Vaultwarden login panel, and will automatically ban all IPs that try to bruteforce your logins. You can run `cscli metrics` to check how many logs have been processed, and `cscli alerts list` to see all the bans triggered.

## 8. Securing your Vaultwarden Admin Panel

As the final step, we're gonna secure the Admin Panel that's still openly accessible to the internet. This will happen entirely in the Cloudflare Dashboard, so you can minimize your terminal for now. To start, open https://one.dash.cloudflare.com/ and sign in with your credentials. It will ask you to create a company, which is not as scary as it sounds. Enter anything you want, it won't matter too much. Should it ask for a billing plan, pick the free option.

Once you're in the panel, switch to "Access" on the left, then "Add an application". Select "Self-hosted" as the type, then enter the following details:

- **Application Name:** "Vaultwarden Admin" (or whatever else you want)
- **Session Duration:** The duration that an authentication should be valid. Pick whatever you feel is safe. I use 60 minutes.
- **Application Domain:** Put your Vaultwarden domain here. The subdomain (`vault` for `vault.domain.com`) in the first field, the main domain (`domain.com`) in the second field, and `/admin` in the third field.
- **Enable App in App Launcher:** Off

Then click "Next". On the following screen, enter the following info: 

- **Policy name:** "Mail PIN"
- Under **Configure Rules** > **Include:** Selector "Emails", and enter your personal mailaddress in the right field. You will receive unlock PINs to this address.

Click "Next" again and change the following on the final screen:

- **Cookie Settings** > **HTTP Only:** On

That's it! You should be brought back to the applications list, where your admin panel now shows up. When you try opening the address from now on, you'll be prompted to enter an email address, which will receive an unlock code. Only the addresses you specified in the rules before will actually be able to receive this code. 

## 9. Setting up Vaultwarden backups

Now that your instance is highly secured, you can safely start storing your passwords there. But just to be prepared for the worst case, you should also add a backup method for your database, in case anything ever goes wrong on your server in the future. For this, you can find my backup script called `run_backup.sh` in this repository. You can download it to your server by `cd`ing into your desired storage location (I have it next to the docker compose files for ease) and running `curl -OJ githublink`. Then, run `crontab -e` and add the following line at the end:

	0 3 * * * /home/docker/vaultwarden/run_backup.sh >/dev/null 2>&1

You obviously need to adapt the location according to where you saved the script. This will run the backup script everyday at 3AM. Per default, the script saves 14 backups, meaning you get backups of the last two weeks, once every day. Feel free to change this as needed.

Technically, you should somehow move these backups completely offsite, to some separate server. You can copy them down to your local machine, rent a storage server on your provider to periodically copy the files to, mount a cloud storage account using rclone and save them to that, or deploy any other solution you want. But this goes beyond the scope of this guide.

## 10. Closing thoughts

That's it! You've successfully bought a server, set up a domain, installed Docker and Vaultwarden, set it all up, locked it down and deployed a basic backup strategy. What a successful day! Now, enjoy setting up all the Bitwarden apps and extensions, knowing that your passwords are about as secure as they'll ever be.
