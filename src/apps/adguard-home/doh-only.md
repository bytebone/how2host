---
# author: rainer            # Add as comment, in case we want to display authors down the road
order: 40                 # Uncomment in case a specific position is desired. Higher number > earlier position
# category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
# icon: shield-check                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
title: "DoH Only"
---

# AdGuard Home with DoH only

## Prerequisites

[!ref icon="check-circle"](../../first-steps/1-vps-setup.md)
[!ref icon="check-circle"](../../first-steps/2-docker-setup.md)
[!ref icon="check-circle"](../../first-steps/3-reverse-proxy/index.md)

## content outline

1. requires no special config on docker, npm or cloudflare
2. adguard exposes no additional ports
3. npm host is set to forward everything to adguard:443
4. adguard should real IP OOB, but might require additional config in NPM (set_header real_ip) / adguard (trusted proxies to nginx / cf ips)
5. dns and control panel are accessible on the same subdomain
