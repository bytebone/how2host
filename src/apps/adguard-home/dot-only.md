---
# author: rainer            # Add as comment, in case we want to display authors down the road
order: 50                 # Uncomment in case a specific position is desired. Higher number > earlier position
# category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
# icon: shield-check                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
title: "Adding DoT"
---

# Adding DoT support

## Adding DNS entry

The Cloudflare proxies only support traffic on a [limited set of ports](https://developers.cloudflare.com/fundamentals/get-started/reference/network-ports/#network-ports-compatible-with-cloudflares-proxy). The DoT port is not one of these, which means we cannot route our DoT requests through the proxy. To solve this, you need to create a new, separate DNS entry in Cloudflare for the subdomain you want to serve DNS requests on. As before, we will be using `dns.your.domain` as our example. 

To do this, open [dash.cloudflare.com](https://dash.cloudflare.com), navigate to your website and the DNS settings page. There, click `Add record` and create four entries: 

Type | Name | IP | Proxy
--- | --- | --- | --- |
A | dns | IPv4 | DNS only
A | *.dns | IPv4 | DNS only
AAAA | dns | IPv6 | DNS only
AAAA | *.dns | IPv6 | DNS only

!!!
The wildcard entries are required for user authentication down the line.
Should your server not have an IPv4 or IPv6 address, you may skip the related entries.
!!!

It is **integral** to disable the Cloudflare Proxy for all of the entries you create here.

## Adjusting the Firewall

The steps in this chapter only apply to you if you've followed the instructions under [Firewall Setup](/hardening/firewall.md), or have done your own changes to the Firewall. 

==- Read along
Your firewall should currently only allow traffic on port 443 coming from Cloudflare IPs, and on your SSH port coming from any IP. Since DoT traffic runs on its own **port 853**, you need to add another firewall exception for this port and from any IP. Only then can devices anywhere freely access the DNS server.

As the firewall restricts access on port 443 to the Cloudflare servers, and the `dns.your.domain` DNS entry bypasses that proxy, the AdGuard dashboard is also no longer reachable under this address. The `dns.` subdomain is now exclusive for DNS DoT traffic, nothing else. To get back into the AdGuard page, you need to create a new, separate host for it, e.g. `adguard.your.domain`. It uses the same `adguard` hostname and `443` port as before, and the regular Cloudflare SSL certificate.

To summarize:
- `dns.your.domain` allows access to the DoT port 853. Use this address in clients that are supposed to use DoT.
- `adguard.your.domain` runs through Cloudflare and allows access to the AdGuard dashboard, as well as DoH.

If you want to remove this split, you have to remove the firewall rule limiting access to port 443, and allow any IP to access that port. You can then use both DoT and DoH on the `dns.your.domain` address. As a side-effect, DoH-requests bypass the Cloudflare proxy, reducing the response time.

!!!warning
Since both DoH and DoT require an encrypted connection, and therefore access via the web address, removing the restriction on port 443 should not pose any security risk. Nonetheless, if you find an alternative approach that enables only the DNS traffic to be allowed from any IP, please open a GitHub issue.
!!!
===

## Configuring AdGuard

All you need to adjust in AdGuard to allow for DoT use is adding the port in the settings page. To do this, open the dashboard, go to `Settings` > `Encryption` and enter "853" into the `DNS-over-TLS port` field. Confirm your changes with the "Save" button at the bottom.

## Using AdGuards DoT

With this, you've finished setting up AdGuard to resolve DoT requests. To use it, switch to the `Setup Guide` tab at the top, followed by the `DNS Privacy` tab below, and read about how to set it up on the different devices.

Note also that you're encouraged to use **Client IDs**, which are additional identifiers to keep apart devices, enhance logging and statistics, and enable fine-grained access controls. To use Client IDs with DoT, add an additional subdomain in front of the DNS subdomain when supplying the DNS address. \
For example, instead of entering `dns.your.domain`, enter `phone.dns.your.domain`. This way, the requests coming from this phone will show up as a separate entry. This will be especially important when you want to secure your server against unauthorized use.

[!ref Finishing Steps](readme.md#further-configuration)