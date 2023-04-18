---
# author: rainer            # Add as comment, in case we want to display authors down the road
# order: 40                 # Uncomment in case a specific position is desired. Higher number > earlier position
category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
icon: shield-check                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
---

# AdGuard Home

## Prerequisites

[!ref icon="check-circle" text="Complete First Steps"](/first-steps/1-vps-setup.md)

## Introduction

### What is AdGuard Home?

AdGuard Home is not a DNS server in the traditional sense; rather, it is a DNS proxy. It does not store a database with all DNS entries itself. Instead, it asks other "upstream" servers for the response. In addition, AdGuard Home can compare the incoming DNS requests to ad-blocking filter lists and block requests that point towards advertising sources.

This means two things: firstly, the upstream DNS servers resolving your requests no longer know your personal IP address and the websites visited by this IP address. They only see the IP address of your server. Additionally, AdGuard Home can spread your requests across many different upstream servers, further improving your anonymity.

Secondly, and this is the main benefit, the filter lists allow for a network-wide ad-blocking experience on every device you have, including in the browser, in apps, and in the operating systems themselves. This feature works regardless of whether the actual devices provide you the option to configure ad-blocking. Additionally, any changes made to your filter lists are automatically applied to every connected device.

[!ref Official Docs](https://github.com/AdguardTeam/AdGuardHome/wiki/Docker)

!!!contrast Disclaimer
AdGuard Home and it's multiple DNS protocols can be set up in countless ways, and the following guide is by no means the easiest approach. If you know exactly what you're doing and which features you want, you can get by with less steps than these. 

This guide however aims at creating a fully-featured groundwork, where you can easily add or remove features at any time without having to retrace your steps and redoing half of the configuration.
!!!

### Different DNS protocols

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

### Which one to use

The decision of which DNS method to use heavily depends on the devices you use daily. If you (or your users) use Android phones, you should offer DoT support. If you need to connect Windows devices, you should look into DoH support. Alternatively, if your home router supports one method or the other, you can use the DNS on the router level don't need to worry about your hardwired home devices anymore (e.g., TV, PC, consoles, and so on).

DoH is the easiest protocol to set up, and the other protocols build on top of the DoH requirements for their functionality. Therefore you only need to decide if you want the additional DoT support or not.

## HTTPS Setup

### Getting an SSL certificate

To use encrypted DNS methods like DoT and DoH, you need an SSL certificate. There are many ways to acquire an SSL certificate, but since Nginx can generate and manage certificates for free and is already running anyways, we'll simply use that to do the job for us.

!!!warning
The Cloudflare certificate you've used on other, regular hosts is not a full certificate and cannot be used for encrypting DNS traffic. Generating a separate certificate is obligatory!
!!!

To start, go into your Nginx interface and switch to the `SSL Certificates` tab. Here, click on `Add SSL Certificate` and choose `Let's Encrypt`. In the popup window, enter the domain name you want to serve DNS requests on, once directly and once with a wildcard (e.g. `dns.your.domain` and `*.dns.your.domain`). Enter an email address (it should be a real one you're reachable under) and tick `Use a DNS Challenge`.

In the new Window, select `Cloudflare` as your DNS provider. The new text field expects a Cloudflare API key, which you can create under https://dash.cloudflare.com/?to=/profile/api-tokens. On this page, click on `Create Token`, followed by `Edit zone DNS`: `Use Template`.

On the new screen, under `Zone Resources`, select your domain. You can also enter your server's IP addresses (both IPv4 and IPv6) to further ensure only that server can use the API key in case it gets leaked. I've chosen to not limit this to ensure no future issues, and instead opted for not saving the API key anywhere. When you're done setting things up, click on `Continue to Summary`, followed by `Create Token` and `Copy` on the token field.

Now, switch back to your Nginx tab where you should still have the "DNS Challenge" Window open. You can now paste your generated token into the textbox, replacing the placeholder value. Finally, agree to the ToS and save your certificate. It might load for a while, while it's working with Cloudflare to create the certificate, but it shouldn't take too long.

Once it's done, you need to confirm the certificate ID. To do so, find the certificate in your SSL Certificate list, click on the three dots to the right and note down the number from the first line. For example, if it says `Certificate #10`, you need to note down the number 10.

### AdGuard Compose file

To get a basic AdGuard instance up and running, open your terminal, create a new work directory for your AdGuard config and add the `compose.yml`:

```yml compose.yml
services:
  adguard:
    image: adguard/adguardhome
    container_name: adguard
    restart: unless-stopped
    # ports:
    #   - 853:853/tcp
    volumes:
      - work:/opt/adguardhome/work
      - conf:/opt/adguardhome/conf
      - nginx_nginx:/opt/adguardhome/cert:ro
    networks:
      - nginx_default

volumes:
  work:
  conf:
  nginx_nginx:
    external: true

networks:
  nginx_default:
    external: true
```

This will create two new volumes for AdGuards work and config files, and also mount the existing Nginx volume, which contains the SSL certificate you just created. Start the container with `docker compose up` and let it set up its configuration. Once it's done, open your Nginx interface and add a new host: 

- **Domain Name:** `dns.your.domain` (or whichever else you generated the SSL certificate for)
- **Forward Hostname:** adguard
- **Port:** 3000
- **Block Common Exploits:** true

Select your Cloudflare SSL Certificate in the SSL tab, **not the one you just generated**. You can now access your admin panel under the domain you configured and go through the initial setup steps. On the first page, set the `Admin interface port` to 3000, while ignoring every other setting. Create your admin user at the end, finish the setup, and re-enter the apps' web address into your address bar. You should now be able to log into the AdGuard interface.

### Encryption

To enable encryption for DoH, as well as the other protocols, look at the top bar and click on `Settings` > `Encryption Settings`, and set the following values:

1. Enable Encryption
2. **Server Name:** the server name you want to resolve DNS requests under, e.g. `dns.your.domain`
3. Set `HTTPS port` to 443
4. Under certificates, click `Set a file path` for both options, and enter the following in the respective fields:
    - Earlier, you [noted down the SSL certificate ID](#getting-an-ssl-certificate). Replace the questionmarks in `npm-??` with that number.
    - **Field 1:** `/opt/adguardhome/cert/live/npm-??/fullchain.pem`
    - **Field 2:** `/opt/adguardhome/cert/live/npm-??/privkey.pem`

!!!danger Attention
Adding the certificates like this has dangerous implications. AdGuard has access to all the configuration files, access logs and certificates of every single one of your hosts. Should someone find an exploit in the AdGuard dashboard, this sensitive data may be at risk. 

You can directly bind-mount the certificates in the AdGuard container, but will then have to reconfigure this every time a new certificate gets generated (4 times a year). If you find a better solution, **please create an issue on GitHub**.
!!!

==- **Error:** Certificate Chain is invalid
If you get this error, the number you've entered is incorrect, or there was a different error reading the directory. 

- Make sure you've copied the filepaths from this guide properly and without missing any characters. This applies mainly to the `compose.yml` line 11, and the paths from the instructions above.
- Ensure that you've written the number exactly like in the web interface (e.g. `npm-2` instead of `npm-02`).

If you still cannot get it to work, you have to figure out the path from the terminal.\
Run the command `docker exec adguard ls /opt/adguardhome/cert/live/`. This should return at least one folder, including one which has the number of your certificate from the Nginx interface.

```!#3
$ docker exec adguard ls /opt/adguardhome/cert/live/
README
npm-10
```
This folders' name is what you need to copy to the path in the AdGuard settings page: `/opt/adguardhome/cert/live/npm-10/fullchain.pem`
===

Once both fields get a green label, click on "Save configuration". Immediately after this, the website will **no longer be reachable**, which is normal. To fix it, switch back to Nginx, edit your AdGuard host configuration, and change the application port from 3000 to 443. After saving, the AdGuard website will be reachable again, and you can continue setting the app up.

## Additional Protocols

### DoT

If you want to add DoT support to your DNS, you need to go through some additional steps to get it all working. Read more about that here.

[!ref](./dot-only.md)

### QUIC

!!!
This guide has not been written yet, and will be added in the near future.
!!!

## Further Configuration

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