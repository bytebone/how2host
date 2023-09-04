---
# author: Alino001            # Add as comment, in case we want to display authors down the road
# order: 40                 # Uncomment in case a specific position is desired. Higher number > earlier position
category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
icon: container                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
# add screenshots
---

# Pihole with LXC

[!ref Official Docs](https://docs.pi-hole.net)
[!ref PXC Docs](https://linuxcontainers.org)

## Prerequisites

[!ref icon="check-circle" text="First Steps"](../../first-steps/1-vps-setup.md)
[!ref icon="check-circle" text="Linux Contanier (LXC)"](https://linuxcontainers.org)

## Installing LXC 

LXC, or a Linux Container, is a VM that runs normal Linux, but without the simulating/emulating issues. It uses your resources to run the VM. It has tools, some templates and a libray for language bindings. It doesnt use alot of resources and is on the latest upstream kernel for maxium support.

To install it on Debian-based systems, you only need to run 1 command:
```
sudo apt install lxc
```

## Making an LXC instance

First of all, you need to create a instance:
```
sudo lxc-create -n pihole -t debian
```
Then, start it up: 
```
sudo lxc-start -n pihole
```
And after those commands are entered, enter the shell:
```
sudo lxc-attach -n pihole
```

## Installing Pi-hole

After successfully entering into the LXC instance, installing Pi-Hole is just one command away: 
```
curl -sSL https://install.pi-hole.net | bash
```

1. Wait for the root check and other checks being done, to see if your LXC is supported.
2. If you havent already, setup a Static IP. This is most likey already done by LXC.
3. Click continue by the "Static IP Needed" Screen.
4. Select Cloudflare (best option in my opinion) in the "Upstream DNS Provider" Screen and click "Ok"
5. After that click "Yes" in the "Blocklist screen" to get a default blocklist.
6. Click Yes in the "Admin Web Interface" and "Web Server" screen, so you can modify the settings via your Webbrowser.
7. "Enable Logging" logs DNS requests, in my opinion, thats needed.
   - (*Only shows when 7 is enabled*) After that select 3. Anonymous mode, but thats my prefrence.
9. After that Pi-Hole will install, just wait a couple of minutes.
10. If everything went well, you will get a "Installation Complete" screen with your password,and where you can login, which is *Your IP*/admin or http://pi.hole/admin. 
11. Make sure to update your password to something you can remember with the command ``pihole -a -p *passwd*`` 

## Optional Stuff

If you want to make your LXC instance start at bootup and run at background you need to do this:

Open the file ``/var/lib/lib/lxc/pihole/config`` and add ``lxc.start.auto = 1`` at the end of the file.

## Closing Words

Thats it! Your Pi-hole is correctly installed in your LXC instance! You only need to configure it with your blacklists and add your IP to the router. Have fun!
