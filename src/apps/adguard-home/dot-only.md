---
# author: rainer            # Add as comment, in case we want to display authors down the road
order: 50                 # Uncomment in case a specific position is desired. Higher number > earlier position
# category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
# icon: shield-check                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
title: "DoT Only"
---

# AdGuard Home with DoT only

## Prerequisites

[!ref icon="check-circle" text="Complete First Steps"](../../first-steps/1-vps-setup.md)

## setup steps

1. adguard exposes 853 only
2. cloudflare gets new unproxied dns entry
3. new host in nginx for the subdomain (dns.) and wildcard subdomain (*.dns.) to manage certificate
  - this requires setting up an API key in cloudflare
  - need to find a guide or someone to practice on
  - the traffic will never run through nginx, so the address doesnt matter. for cleanliness sake use adguard 443
4. 

## content outline

1. firewall:  no 443 from non CF IPs, 853 open for everyone
2. unproxied `dns.*` dns entry
3. adguard exposes 853, bypassing nginx completely
4. adguard control panel access on different subdomain through nginx
5. npm generates separate SSL cert for this subdomain