---
# author: rainer            # Add as comment, in case we want to display authors down the road
# order: 40                 # Uncomment in case a specific position is desired. Higher number > earlier position
category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
icon: shield-check                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
---

# AdGuard Home

!!!warning
This is a content skeleton and not yet fully written out. Proceed with caution.
!!!

## What is AdGuard Home?

adguard home is not a **dns server**, it is a **dns proxy**. this means that agh does not store a database with all DNS entries itself. instead, it asks other servers for the response. additionally, agh can compare the incoming dns requests to adblocking filter lists, and block requests that point towards ad sources. 

this has two consequences: for one, the upstream DNS servers that resolve your requests no longer know your IP address and what websites this IP address visits. they only see the IP address of your server. additionally, agh spreads your requests across many different upstream servers, further improving your anonymity. \
secondly, and this is the main one, the filter lists allow for a network wide adblocking experience, on every device you have, in the browser, in apps, in the operating systems themselves, no matter if the devices themself give you the option to configure this. and when changing something about your filterlists, you dont need to even touch your individual devices to update the local config. 

## different DNS methods

there are a bunch of different ways a device can make a dns request to a dns resolver:

!!!danger
link an external source needed
!!!

=== DNS-over-UDP on port 53
this is the worst method. unencrypted, easy to read by network providers, and when hosting your own dns server, the port gets abused regularly. **this port should not be open**.
=== DNS-over-HTTPS on port 443
this uses the same port that encrypted web traffic uses. this makes the traffic completely intermingled with all the other global traffic, and hard to filter out by ISPs or attackers. it can also be used behind the cloudflare proxy, though with additional latency. DoH is natively supported on many devices, but requires additional software on android phones. 
=== DNS-over-TLS on port 853
this method uses its own port for communication. it has to bypass the cloudflare proxy, so if youre extremely dedicated to hide your server ip, do not use this method. DoT is natively supported on most devices and routers, but requires additional software on windows.
==- DNS-over-QUIC on port (8)853
this uses the same port as DoT by default, but can be set to use different ports as well. it offers DoT-like encryption, while promising less latency, and will require additional apps on most devices. this method will not be covered in these guides.
===

### which one should i use?

the decision which DNS method to use depends heavily on the devices you use daily. if you (or your users) use android phones, you should offer DoT support. if you need to connect windows devices, you should look into DoH support. or maybe your home router supports one method or the other, and then you dont need to worry about your hardwired home devices anymore (tv, pc, consoles, and so on).

the following guides will look into three different configurations with DoH and DoT, and you can decide which fits your situation best.

## Different Setup Methods

!!!warning Attention
these guides cover only some of the many possible approaches. there are many more ways to make it work, but i found these to be the most sensical and broadly applicable.
!!!

### DoT only

**Pro:** natively supported on almost any device, TLS encryption\
**Con:** requires software on windows, exposes VPS IP through dns entry

[!ref](./dot-only.md)

### DoH only

**Pro:** no compromise on VPS IP protection, every dns request runs through CF and Nginx\
**Con:** requires software on android, highly increased response time (5-7x) due to the proxy chain

[!ref](./doh-only.md)

### DoT and DoH

the DoT method already somewhat enables the use of both DoT and DoH, but in a not so practical way. this section just provides some additional tips how to make it less ugly to use, in case you want to actively use both.

[!ref](./dot-doh.md)

## Installing AdGuard Home

[!ref Official Docs](https://github.com/AdguardTeam/AdGuardHome/wiki)

as with nginx, first create a folder to store your config files in, e.g. `mkdir -p /home/docker/adguard`, and `cd` into it. now, start editing the compose file with `nano compose.yml` and paste the following contents:

```yml compose.yml
services:
  adguard:
    image: adguard/adguardhome
    container_name: adguard
    restart: unless-stopped
    ports:
      - 853:853/tcp
    volumes:
      - work:/opt/adguardhome/work
      - conf:/opt/adguardhome/conf
#      - /var/lib/docker/volumes/nginx_nginx/_data/archive/npm-20:/opt/adguardhome/cert:ro
    networks:
      - nginx_default

volumes:
  work:
    external: true
  conf:
    external: true

networks:
  nginx_default:
    external: true

```
