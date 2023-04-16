---
# author: rainer            # Add as comment, in case we want to display authors down the road
# order: 40                 # Uncomment in case a specific position is desired. Higher number > earlier position
category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
icon: shield-check                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
---

# AdGuard Home

## Prerequisites

[!ref icon="check-circle" text="Complete First Steps"](/first-steps/1-vps-setup.md)

## What is AdGuard Home?

AdGuard Home is not a DNS server; rather, it is a DNS proxy. This means that AdGuard Home does not store a database with all DNS entries itself. Instead, it asks other servers for the response. In addition, AdGuard Home can compare the incoming DNS requests to ad-blocking filter lists and block requests that point towards advertising sources.

This means two things: firstly, the upstream DNS servers that resolve your requests no longer know your personal IP address and the websites visited by this IP address. They only see the IP address of your server. Additionally, AdGuard Home spreads your requests across many different upstream servers, further improving your anonymity.

Secondly, and this is the main benefit, the filter lists allow for a network-wide ad-blocking experience on every device you have, including in the browser, in apps, and in the operating systems themselves. This feature works regardless of whether the actual devices provide you the option to configure ad-blocking. Additionally, any changes made to your filter lists are automatically applied to every connected device.

[!ref Official Docs](https://github.com/AdguardTeam/AdGuardHome/wiki/Docker)

## Different DNS methods

There are four differenct methods with which a device can make a DNS request to a DNS resolver:

!!!
If you want further information on the differences, you can read [this explanation](https://help.nextdns.io/t/x2hmvas/what-is-dns-over-tls-dot-dns-over-quic-doq-and-dns-over-https-doh-doh3)
!!!

=== DNS-over-UDP on port 53
This method is unencrypted, easy to read by network providers, and when hosting your own DNS server, the port gets abused regularly. **This port should not be open**.
=== DNS-over-HTTPS on port 443
This utilizes the same port as encrypted web traffic. By doing so, the traffic becomes completely intertwined with all other global traffic, making it difficult for both ISPs and attackers to filter out. Additionally, it can be used behind the Cloudflare proxy, although this may result in increased latency. DoH is natively supported on many devices, but requires additional software on Android phones.
=== DNS-over-TLS on port 853
This method uses its own port for communication. It has to bypass the Cloudflare proxy, so if you're extremely dedicated to hiding your server's IP, do not use this method. DoT is natively supported on most devices and routers, but requires additional software on Windows.
==- DNS-over-QUIC on port (8)853
This uses the same port as DoT by default, but can be set to use different ports as well. It offers DoT-like encryption while promising lower latency and will require additional applications on most devices. However, this method will not be covered in these guides.
===

### Which method to use

The decision of which DNS method to use heavily depends on the devices you use daily. If you (or your users) use Android phones, you should offer DoT support. If you need to connect Windows devices, you should look into DoH support. Alternatively, if your home router supports one method or the other, you can use the DNS on the router level don't need to worry about your hardwired home devices anymore (e.g., TV, PC, consoles, and so on).

The following guides will look into three different configurations with DoH and DoT, and you can decide which fits your situation best.

## Different Setup Methods

!!!warning Attention
These guides cover only some of many possible approaches. There are many more ways to make it work, but I found these to be the most sensical and broadly applicable.
!!!

### DoT only

**Pro:** natively supported on almost any device, uses TLS encryption\
**Con:** requires software on windows, exposes VPS IP through a DNS entry

[!ref](./dot-only.md)

### DoH only

**Pro:** no compromise on VPS IP protection, every DNS request runs through Cloudflare and Nginx\
**Con:** requires software on Android, suffers from highly increased response time (5-7x) due to the proxy chain

[!ref](./doh-only.md)

### DoT and DoH

This combines both Pros and Cons from the selective approaches. Since the DoT method already somewhat allows DoH use, this section is only an extension of the DoT guide with the goal of making the use of DoH more practical and streamlined.

[!ref](./dot-doh.md)

## AdGuard Configuration

Once you've finished setting up AdGuard with the method you desire, you can continue here to finish setting up AdGuard.

### General

The settings here are quite opinionated and depend on how you want to use the instance. Should you be uncertain, feel free to fall back to these exemplatory values:

- **Check** "Block domains using filters" and "Use AdGuard browsing security"
- **Check** "Enable Log" and set a **Query log retention** of 24 hours
- **Check** "Enable Statistics" and set a **Statistics retention** of 24 hours

### Client

As mentioned in the method guides, you're able and encouraged to use **Client IDs** to tell apart the different devices accessing your service. This makes the logs clearer, provides better statistics, and allows to tell which devices might be accessing infected sources.

While you don't need to need to add these clients here, doing so allows you to join multiple clients into one entry (`my-phone` and `my-laptop` as one client, and `dads-phone` as another client). It also allows to use different filtering settings per client, which can be useful in certain situations.

To add a persistent client, click on `Add Client` and enter the `Client name` which will show up in the interface, the `client tags` with which you can categorize the device, and the `identifier` that you're using on the device in the configured DNS address (e.g. `phone` from `phone.dns.your.domain`).

### DNS

#### Upstream DNS
As explained in the introduction, AdGuard is dependant on other "upstream" DNS servers to get its responses. On this page, you enter these servers you want AdGuard to use. It is recommended to chose servers that are close to both you and your VPS for fast responses, as well as servers that have good privacy policies and support encrypted DNS channels. You should do research on the available providers in your country. As a general starting point, refer to [this article](https://securitytrails.com/blog/dns-servers-privacy-security#content-best-dns-servers-for-security-and-privacy).

Once you've entered your desired DNS servers, change the request mode setting to `Parallel requests` for maximum speed.

Under `Bootstrap DNS servers`, supply the unencrypted addresses of some of the major DNS providers, e.g. Cloudflare (`1.1.1.1` & `1.0.0.1`), Quad9 (`9.9.9.9` & `149.112.112.112`) or Google (`8.8.8.8` & `8.8.4.4`). These servers will only be used to resolve the names of your main DNS servers, nothing else.

Finally, check `Enable reverse resolving of clients' IP addresses` for some extra information in your query logs and save.
#### DNS server configuration

- Set `Rate limit` to 6
- Check `Enable EDNS` and `Enable DNSSEC`

#### DNS cache configuration

- `Cache Size` to 10000000
- `Minimum TTL` to 7200 (equals 2 hours)
- `Maximum TTL` to 172800 (equals 48 hours)

#### Access Settings

If you want to limit the devices that are able to use your service, you can enter a list of Client IDs in this field. As soon as you enter a single entry here and save, access from anything not on the list will be denied, so be careful to enter every device identifier you are using.

### Filters

The `DNS blocklists` page under `Filters` contains the list of adblock-lists that the DNS server should deny access to, and is where you configure the adblocking behaviour of the server. To get started, click on `Add blocklist` and `Choose from the list` to get a handy list of sources to quickly add.

Which lists to add is very opinionated. Be aware however that higher amounts of total rules also increase the RAM consumption of the app, and negatively affect the response time of every request. Don't simply add every list there is, but pick the most efficient ones carefully. You can always check the query logs and see which lists are blocking requests and disable ones that don't do any work.