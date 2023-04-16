---
# author: rainer            # Add as comment, in case we want to display authors down the road
order: 50                 # Uncomment in case a specific position is desired. Higher number > earlier position
# category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
# icon: shield-check                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
title: "DoT Only"
---

# AdGuard Home with DoT only

This guide will cover the setup if you're only focussing on DoT availability. Note that DoH will still be available, but with minor complications. 

## Initial Network Checks

If you've followed the instructions under [Firewall Setup](/first-steps/4-firewall.md), your firewall should currently only allow traffic on port 443 coming from Cloudflare IPs, and on your SSH port coming from any IP. Since DoT traffic runs on its own **port 853**, you need to add another firewall exception for this port and from any IP. 

## Adding DNS entry

The Cloudflare proxies only support traffic on a [limited set of ports](https://developers.cloudflare.com/fundamentals/get-started/reference/network-ports/#network-ports-compatible-with-cloudflares-proxy). The DoT port is not one of these, which means we cannot route our DoT requests through the proxy. To solve this, you need to create a new, separate DNS entry in Cloudflare for the subdomain you want to serve DNS requests on. For this guide, we will be using `dns.your.domain`. 

To do this, open [dash.cloudflare.com](https://dash.cloudflare.com), navigate to your website and the DNS settings page. There, click `Add record` and create four entries: 

Type | Name | IP | Proxy
--- | --- | --- | --- |
A | dns | IPv4 | DNS only
A | *.dns | IPv4 | DNS only
AAAA | dns | IPv6 | DNS only
AAAA | *.dns | IPv6 | DNS only

!!!
The wildcard entries are required for a sort of "user authentication" down the line.
Should your server not have an IPv4 or IPv6 address, you may skip the related entries.
!!!

It is **integral** to disable the Cloudflare Proxy for all of the entries you create here.

## Getting an SSL certificate

To use encrypted DNS methods like DoT and DoH, you need an SSL certificate. There are many ways to acquire an SSL certificate, but since Nginx can generate and manage certificates, and that's already running anyways, we'll simply use that to do the job for us.

!!!warning
The Cloudflare certificate you've used on other, regular hosts is not a full certificate and cannot be used for encrypting DNS traffic. Generating a separate certificate is obligatory!
!!!

To start, go into your Nginx interface and switch to the `SSL Certificates` tab. Here, click on `Add SSL Certificate` and choose `Let's Encrypt`. In the popup window, enter the domain name you want to serve DNS requests on, once directly and once with a wildcard (e.g. `dns.your.domain` and `*.dns.your.domain`). Enter an email address (it should be a real one you're reachable under) and tick `Use a DNS Challenge`.

In the new Window, select `Cloudflare` as your DNS provider. The new text field expects a Cloudflare API key, which you can create under https://dash.cloudflare.com/?to=/profile/api-tokens. On this page, click on `Create Token`, followed by `Edit zone DNS`: `Use Template`.

On the new screen, under `Zone Resources`, select your domain. You can also enter your server's IP addresses (both IPv4 and IPv6) to further ensure only that server can use the API key in case it gets leaked. I've chosen to not limit this to ensure no future issues, and instead opted for not saving the API key anywhere. When you're done setting things up, click on `Continue to Summary`, followed by `Create Token` and `Copy` on the token field.

Now, switch back to your Nginx tab where you should still have the "DNS Challenge" Window open. You can now paste your generated token into the textbox, replacing the placeholder value. Finally, agree to the ToS and save your certificate. It might load for a while, while it's working with Cloudflare to create the certificate, but it shouldn't take too long.

Once it's done, you need to confirm the certificate ID. To do so, find the certificate in your SSL Certificate list, click on the three dots to the right and note down the number from the first line. For example, if it says `Certificate #10`, you need to note down the number 10.

## Starting AdGuard

Now, we can start setting up the actual AdGuard container. Go into your terminal, create a new work directory for your AdGuard config and add the `compose.yml`:

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

This will expose the port 853 for use with DoT, create two new volumes for AdGuards work and config files, and mount the existing Nginx volume, which contains the certificate you've created. Start the container with `docker compose up -d && docker compose logs -f` and let it set up its configuration. Once it's done, switch back to your Nginx interface and add a new host: 

- **Domain Name:** e.g. `adguard.your.domain`. **Has to be** different from the domain you're using for DNS resolution!
- **Forward Hostname:** adguard
- **Port:** 80
- **Block Common Exploits:** true

Remember to select your Cloudflare SSL Certificate in the SSL tab. You can now access your admin panel under the domain you configured and register your admin account.

!!!danger
User management might be limited to the config file. This was uncertain at the time of writing and will be confirmed soon.
!!!

## Configuring AdGuard

There are a bunch of things to configure in AdGuard's interface. You can find all the screens at the top under `Settings`. This section will only cover Encryption, the rest of the settings apply to any method and are therefor in the [main guide](readme.md#adguard-configuration).

### Encryption

1. Enable Encryption
2. **Server Name:** the server name you want to resolve DNS requests under, e.g. `dns.your.domain`
3. Set `HTTPS port` to 443 and `DNS-over-TLS port` to 853
4. Under certificates, click `Set a file path` for both options, and enter the following in the respective fields:
    - Earlier, you [noted down the SSL certificate ID](#getting-an-ssl-certificate). Replace the questionmarks in `npm-??` with that number.
    - **Field 1:** `/opt/adguardhome/cert/live/npm-??/fullchain.pem`
    - **Field 2:** `/opt/adguardhome/cert/live/npm-??/privkey.pem`

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

Once both fields get a green label, click on "Save configuration". Immediately after this, the website will **no longer be reachable**, which is normal. To fix it, switch back to Nginx, edit your AdGuard host configuration, and change the application port from 80 to 443. After saving, the AdGuard website will be reachable again, and you can continue setting the app up.

## Using AdGuards DoT

With this, you've finished setting up AdGuard to resolve DoT requests. To use it, switch to the `Setup Guide` tab at the top, followed by the `DNS Privacy` tab below, and read about how to set it up on the different devices.

Note also that you're encouraged to use **Client IDs**, which are additional identifiers to keep apart devices, enhance logging and statistics, and enable fine-grained access controls. To use Client IDs with DoT, add an additional subdomain in front of the DNS subdomain when supplying the DNS address. \
For example, instead of entering `dns.your.domain`, enter `phone.dns.your.domain`. This way, the requests coming from this phone will show up as a separate entry. This will be especially important when you want to secure your server against unauthorized use.

Should you want to use DoH for singular occasions, you can do so by using your **AdGuard Web Interface address** instead of the usual resolver address, e.g. `https://adguard.your.domain/dns-query/phone`, replacing `phone` with the Client-ID you want to use.

[!ref Finishing Steps](readme.md#adguard-configuration)