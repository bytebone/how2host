---
# author: rainer
icon: shield-lock
---

# Vaultwarden

## Prerequisites

[!ref icon="check-circle" text="Entire First Steps"](../../first-steps/1-vps-setup.md)

## Installing Vaultwarden

[!ref Official Docs](https://github.com/dani-garcia/vaultwarden/wiki)

You're coming along nicely, and are finally ready to actually install Vaultwarden. As you're getting more familiar with Linux navigation, Docker and nginx hosts, I'll be summarizing more and more from here on out.

To start, make a new directory for the Vaultwarden config: `mkdir /home/docker/vaultwarden` and open it for editing: `nano /home/docker/vaultwarden/compose.yml`. Paste the following contents:

```yml compose.yml
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
```

Again, some notes on this compose file:

- To make Vaultwarden accessible from the outside world, we need to add it to a network that Nginx is also in. To make it easy, we simply add it to the network that Nginx created on startup. Note that it's actually called differently than in the Nginx compose file, because docker prepends the project name when creating networks, volumes and unnamed containers.
	- To do this, we need to add the `external: true` property to the network when we define it at the end of the file. This specifies that the network does not belong to this project, but is an outside object.
- We've also specified a new line: `env_file: .env`. These files store "environment variables" that many containers use for customization.
- Vaultwarden uses a PostreSQL database to store all the data you provide it. This database **doesn't need to be** accessible from the outside world - it would be very problematic if it was. Therefor, we don't add it to the Nginx network. We create a separate network, just for the communication between Vaultwarden and the database. No other service that's not related to Vaultwarden should be in this network!
- In this compose file, I've specified the postgres release `14-alpine`. This will be updated in the future, to `15-alpine`, `16-alpine` and so on. Check the [official Docker repo](https://hub.docker.com/_/postgres) for the latest version and change this accordingly.

As mentioned, we also need an environment variables file. You can get it from the [official repo](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template), or use this direct command to download it right into your project folder: 

```
curl -o /home/docker/vaultwarden/.env -L https://raw.githubusercontent.com/dani-garcia/vaultwarden/main/.env.template
```

Now, open the file with `nano .env` and change the following lines:

- `DATABASE_URL` specifies the database connection. It should look like this: 

  ```
  DATABASE_URL=postgresql://vault:<db_password>@vaultwarden-db:5432/vault

  ```
  - Use the <db_password> you've specified in the compose file!
- `WEBSOCKET_ENABLED=true`
- `DISABLE_ADMIN_TOKEN=true`
  - This will allow anyone to access the admin panel. We will lock this down at the end.
- `DOMAIN=https://vault.your.domain`
	- Obviously, set this to the domain you wanna access Vaultwarden on. 

That's pretty much it! You can now run `docker compose up -d` to install and run the containers, and `docker compose logs -f` to jump into the logs of it all to see that it works fine. By splitting the two commands, you can quit out of the logs without shutting down the container later. 

## Exposing Vaultwarden

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
    ```
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    ```
	2. The second entry disables webhooks on a subdirectory
		- Location: `/notifications/hub/negotiate`
		- Hostname: `vaultwarden-app`
		- Port: `80` (or whatever port the app is running on in your case)

From this point onwards, you should be able to access Vaultwarden on the specified domain. You can watch the Docker logs for a bit while creating your account, to make sure there are no errors. 

## Securing Vaultwarden with CrowdSec

!!!info
This chapter will soon move into its own article
!!!

Vaultwarden is already very secure. It brings its own rate limiter for login attempts to combat bruteforcing, and since you're behind the Cloudflare Proxy, you're also protected from DDoS and other attacks. There's barely anything left to do, but we can go one final step. Should someone find this service and decide to bruteforce your login, we can ban their entire IP to permit access to the entire server. This will take some setup, so stay with me here.

Many people would use Fail2Ban for this case, but I've found CrowdSec to be both easier to manage and especially monitor, and more efficient in its banning of offenders. Feel free to figure out Fail2Ban on your own if you so desire - this guide will cover CrowdSec.

### Admin Panel Setup

Before we can do anything meaningful, we need to change an integral setting in the Vaultwarden Admin panel. To do this, open your Vaultwarden Website, then append `/admin` to the URL (e.g. `vault.your.domain/admin`). This should directly lead you to the unsecured admin panel - don't worry, we'll fix that at the end of the guide. For now, navigate into the `Advanced Settings` category and enter `CF-Connecting-IP` into the `Client IP header` field. This enables Vaultwarden to see the real IP addresses of people connecting to your instance, instead of the Cloudflare Proxys' IP. 

> While you're here, you can also change some other settings, like disabling new signups, or anything else you deem useful.

Save your changes with the button at the bottom, and close the tab. 
If you wanna control that this has worked, run `docker logs -f vaultwarden-app`, open the Vaultwarden page and log in. You should see your IP in the Docker logs. Should you not have made an account yet, you can also try logging in with fake credentials.

### Installing CrowdSec

[!ref Official Docs](https://docs.crowdsec.net/docs/getting_started/install_crowdsec)

Now get back to your terminal, and run the following commands, one by one:

```
$ curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
$ sudo apt install crowdsec
$ sudo apt install crowdsec-firewall-bouncer-iptables
$ cscli collections install Dominic-Wagner/vaultwarden
```

With these commands, you've installed CrowdSec, their firewall bouncer, and the Vaultwarden configuration. Now, we need to set these components up properly to enable them to communicate with each other.

First, run `nano /etc/crowdsec/acquis.yaml` to edit the **CrowdSec Acquisition File**, where we will add the Docker logs of the Vaultwarden container. Add the following text at the end of the file:

```yml acquis.yaml
---
source: docker
container_name:
  - vaultwarden-app
labels:
  type: Vaultwarden
---
```

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

## Securing the Admin Panel

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

## Setting up Vaultwarden backups

Now that your instance is highly secured, you can safely start storing your passwords there. But just to be prepared for the worst case, you should also add a backup method for your database, in case anything ever goes wrong on your server in the future. For this, you can find my backup script called `run_backup.sh` in this repository. 

==- Check the script
:::code source="./run_backup.sh" :::
[!button variant="ghost" text="Open in GitHub" target="blank" icon="link-external" iconAlign="right"](https://github.com/justrainer/selfhost-guides/blob/main/vaultwarden/run_backup.sh)
===

You can download it to your server by `cd`ing into your desired storage location (I have it next to the docker compose files for ease) and running `curl -OJ https://github.com/justrainer/selfhost-guides/blob/main/vaultwarden/run_backup.sh`. Then, run `crontab -e` and add the following line at the end:

``` crontab
0 3 * * * /home/docker/vaultwarden/run_backup.sh >/dev/null 2>&1
```

You obviously need to adapt the location according to where you saved the script. This will run the backup script everyday at 3AM. Per default, the script saves 14 backups, meaning you get backups of the last two weeks, once every day. Feel free to change this as needed.

Technically, you should somehow move these backups completely offsite, to some separate server. You can copy them down to your local machine, rent a storage server on your provider to periodically copy the files to, mount a cloud storage account using rclone and save them to that, or deploy any other solution you want. But this goes beyond the scope of this guide.

## Closing Words

That's it! Your Vaultwarden is completely secured, every common attack vector is locked down. You can now start importing or adding your passwords to this vault, invite friends and family to it, and sign into the official Bitwarden applications using your own instance! 