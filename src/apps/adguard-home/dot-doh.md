---
# author: rainer            # Add as comment, in case we want to display authors down the road
# order: 0                 # Uncomment in case a specific position is desired. Higher number > earlier position
# category: [Privacy, Security]    # Add app categories you seem fit. Not yet standardized.
# icon: shield-check                  # Add an icon from https://primer.github.io/octicons that fits the app / stack
title: "DoT & DoH"
---

# AdGuard Home with DoT & DoH

## Prerequisites

[!ref icon="check-circle" text="Complete First Steps"](../../first-steps/1-vps-setup.md)

## content outline

combination of the former two approaches.

follow steps of DoT setup first, then additionally:
- for easier: just set it up for DoT and access DoH under the control panel host
- for prettier: allow 443 connections from any ip (instead of CF only) in server firewall, then DoH will work with the dns.* subdomain