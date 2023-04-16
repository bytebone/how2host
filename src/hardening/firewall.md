---
# author: rainer
order: 50
---

# Strict Firewall

## Short summary

!!!info
This is currently only a summary of what needs to be done. Maybe someone can add some guidance for `iptables` in the future, as a reference.
!!!

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