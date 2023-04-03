---
# author: rainer
order: 50
---

# Initial VPS Setup

## Prerequisites
- Basic knowledge in Terminal and Linux CLI usage
- Very basic knowledge of networking
- **5-10 $ a month** for the server
- **5-15 $ a year** for the domain name
- You will create multiple accounts, for buying your domain, renting your server, and securing your VPS with Cloudflare

## Getting a Domain

In order to properly use Vaultwarden (or any other services you'd be hosting on your server), you need a domain name. This can be pretty much anything you want that hasn't been used yet. There are countless vendors for domain names, which is why I like to use [TLD-List](https://tld-list.com/) as a starting point. You'll probably want to set the filters to something like

- **Cheapest Register Price:** 0-20
- **Character Count:** 2-6
- **Domain Level:** Top-level domains
- **WHOIS Privacy:** Supported
- **TLD Phase:** In General Availability

Now, you can brainstorm some ideas how you could call your domain, enter it into the search box up top, and see both what that domain name would cost with different TLDs, as well as if they're still available. **Keep in mind** that not only the registering price matters - you'll have to renew the domain at some point, usually after a year. Don't fall for a cheap registrar price that renews at 3-10x that! 

**Additionally**, when you found a TLD you like, click on its' label to see the list of available registrars. You should look for one that supports both **free WHOIS privacy** and **DNS settings**. While the former is only very much recommended, the latter is crucial!

Once you found something you like, go through the purchasing process as with any online purchase.

## Getting a VPS

This is a step with which I can hardly help you. There are countless VPS providers with varying price and quality. Which one you should choose depends on your region of living and your budget. Personally, I've been happy with [Hetzner](https://www.hetzner.com/cloud), who offer hosting in Europe and America. Others that I haven't tried, but who are big and known games in the server space, are [Linode](https://www.linode.com/products/shared/), [Hostinger](https://www.hostinger.com/vps-hosting), [Digital Ocean](https://www.digitalocean.com/solutions/vps-hosting) and [OVHCloud](https://us.ovhcloud.com/vps/), with many more options when spending some time on Google and in comparisons / benchmarks of different providers in your country. You can also check out [LowEndTalk](https://lowendtalk.com/), which is an online forum for affordable hosting solutions. 

The only thing you should really be looking for is a server that supports an Ubuntu image out of the box. I've yet to see a VPS provider that doesn't, but still look out for it. Regarding specs, a small spec server is more than enough. I've been running my applications on **2 shared cores, 2GB of RAM and 40GB of storage** without problems. You can obviously go higher if you have the cash to do so.

After you've found a provider you're confident in and have purchased the server, you should be presented with an **IP address, a username and a root password**. How you get these differs between providers; sometimes they are laid out in the server dashboard, sometimes you receive them via e-mail. 

Once you have these credentials on hand, open the terminal of your choice (*CMD* on Windows, *Terminal* on Mac, Linux users know it themselves) and enter the following command:

```
ssh root:<root password>@<ip address>
```
   
Replace `<root password>` and `<ip address>` with their respective strings from your server dashboard. After pressing enter and a short pause, you should be connected to your server.

!!!
Should this fail, use only `ssh root@<ip address>` and enter the root password when prompted.
!!!

## Securing the VPS

We don't want your VPS to be open to the internet or easy to find, do we? Let's change some basic settings to make sure the server is tough to find and even tougher to hack.

### Generating and installing SSH keys

!!!warning
This step assumes you've never set up SSH keys before. If you have, make sure to not overwrite your existing keys!
!!!

As our first step, we're going to **generate and install** an SSH certificate. This is a much safer authentification method compared to passwords, and you won't even have to enter anything when connecting to your server. 
To start, you're gonna disconnect from the server with the `exit` command. Now, back in your local machines' terminal, run `ssh-keygen -b 4096`. When asked for a filepath, press enter **if you don't already have SSH keys with the default name**, or feel free to enter another save location. When asked for a passphrase, simply press enter twice, entering nothing.
If everything went fine, the command will display the output paths for two files, along some other unrequired details.

Now, run the command `ssh-copy-id -f .ssh/id_rsa.pub root@<ip address>`, press enter, paste the root password once more, and the command should exit without errors. Should you have used another save location or file name when generating the SSH key, use that in place of `.ssh/id_rsa.pub`. In any case, use the file ending in `.pub`, **not the file without a file extension!**

### Securing the SSH access

[!ref Source Guide](https://linuxize.com/post/how-to-change-ssh-port-in-linux/)

Now, we're going to lock down your server to make finding it much harder for bots scouring the internet. Connect to your server with the same SSH command as before, and enter the root password if prompted.
Once you're connected, run `nano /etc/ssh/sshd_config`, which will open a long text file. Here, find the following lines, remove the leading # and change the values as written:

```
Port <any number between 1024 and 65536>
PermitRootLogin prohibit-password
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
```

Make sure that these lines only exist once in the config file - I've seen them duplicated at the end of the file for some server hosters. Should that be the case, delete these duplicated lines using `CTRL+Shift+K`. Once you've changed the settings, press `CTRL+X` followed by `y` to save and exit. Then, run `systemctl restart ssh` to apply the changes. 
To verify that SSH daemon is now listening on the new port, run `lsof -Pni | grep sshd`, which should return something like this:

```
sshd    24167    root  3u  IPv4  99527151   0t0  TCP *:4334 (LISTEN)
sshd    24167    root  4u  IPv6  99527153   0t0  TCP *:4334 (LISTEN)
sshd    29370    root  4u  IPv4  10998432   0t0  TCP 172.0.0.1:4334->56.223.57.86:51434 (ESTABLISHED)
```

Where `4334` would be the port you've specified.

To finish this this section, disconnect from the server once more, returning to your local terminal, and run the command `nano .ssh/config`. 

!!!warning
This command will not work on Windows, and I don't know which command will. Feel free to make a PR adding this info. Until then, you can 
!!!

An empty text editor should open, in which you will paste the following text:

```
Host <server name>
  HostName <ip address>
  User root
  Port <SSH port>
  IdentityFile ~/.ssh/id_rsa
```

Replace the <server name> with any memorable shorthand you want - you will use it to connect to the server in the future. Also enter the servers' IP address and the SSH port you've specified before, and make sure the SSH key location is correct. Once done, leave the editor with the same keybinds as before (`CTRL+Shift+X` followed by `y`). 

From now on, to connect to the server, all you need to enter is `ssh <server name>`! So, as an example, if you called the server "vps" in your config, you'd enter `ssh vps`, press enter, and connect in a matter of seconds, without ever needing a password.

## Connecting your Domain and VPS via Cloudflare

[!ref Official Docs](https://developers.cloudflare.com/learning-paths/get-started/#live_website)

To access your services with your domain name, we need to connect one to the other first. To help us do this **securely**, we'll make use of Cloudflare's DNS Proxy service, which will hide your server IP from anyone accessing your domain, increasing security by obfuscation. To start, go to https://dash.cloudflare.com/sign-up and create an account.

Once you're in the dashboard, click "Add Site", enter the domain name you've chosen before and select the free plan when prompted. On the next page, you should be confronted with the DNS entries on the domain - of which you probably have none. Should there be any A or AAAA entries, remove them, then add new ones, providing your servers IP address. 

- use A entries for IPv4 (123.456.78.9)
- use AAAA entries for IPv6 (2a02:81b4:c0:27:b227:9b:::)

For each IPv4 and IPv6, make two DNS entries - one using `@` as name, and one using `*`. This ensures that **every** request gets directed at your server, no matter what.

Once you're done, confirm and make note of the following page. You will now need to go to the provider where you've bought your domain name, and find the DNS settings panel. You're looking for the setting to change the **domains' nameservers**. Change them according to Cloudflares' instructions, and confirm on the Cloudflare page once you're done. This change can take some time to propagate. You'll need a bit of patience until it comes through, but Cloudflare will send you an e-mail once it's completed.

While this is processing, you can click through the different menus of the page and get an overview of all the things you can change. Feel free to change what you're confident you understand, or read along on the next section.

