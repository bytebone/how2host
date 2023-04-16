---
# author: rainer
---

# CrowdSec

## How does it work

CrowdSec functions similarly to Fail2Ban. It reads log files (or other data streams), finds failed login attempts via patterns, and bans IP addresses that repeatedly fail logins. Contrary to Fail2Ban however, it then shares the offending IP detected on your host with the global CrowdSec network and alerts any other instance of that address. Same goes for your host - once an IP attacks any host using CrowdSec, their address is automatically banned on your host as well.

CrowdSec also has [a hub](https://hub.crowdsec.net/browse), where users share configurations for many different apps. This way, you rarely have to write a parser yourself, instead simply installing the configuration.

After the installation, CrowdSec will automatically start monitoring your SSH port. The **default bantime is 4 hours**, but that's configurable in the config file. If you want to learn more about how to configure and use CrowdSec, please refer to their documentation.

## Installing CrowdSec

[!ref Official Docs](https://docs.crowdsec.net/docs/getting_started/install_crowdsec)

Open your terminal, and run the following commands, one by one:

```
$ curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
$ sudo apt install crowdsec
$ sudo apt install crowdsec-firewall-bouncer-iptables
```

This adds the CrowdSec repository to apt, installs the CrowdSec client (which orchestrates the different components) and the firewall bouncer (which does the actual banning of IPs). 

## Configure Firewall Bouncer

The firewall bouncer needs some initial setup. To enable IPv6 support, run `ip6tables -N DOCKER-USER`, adding a needed IPv6 chain. Then run both `iptables -L` and `ip6tables -L`, each time checking that the entry `Chain DOCKER-USER` exists.

!!!
This `DOCKER-USER` chain is important, since it's the one Docker uses to manage access to its containers. If this chain isn't used, access to your services won't be restricted in case of a ban.
!!!

Now, run `nano /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml` to adjust the bouncer config:

- Change `disable_ipv6:` to `false`
- Uncomment `- DOCKER-USER` under `iptables_chains`

==- :icon-file: Complete File
Confirm that the highlighted lines match your file:
```yml #1,15,27,29
mode: iptables
pid_dir: /var/run/
update_frequency: 10s
daemonize: true
log_mode: file
log_dir: /var/log/
log_level: info
log_compression: true
log_max_size: 100
log_max_backups: 3
log_max_age: 30
api_url: http://127.0.0.1:8080/
api_key: h8a9shd8asdhja09sdh71928dh10j211
insecure_skip_verify: false
disable_ipv6: false
deny_action: DROP
deny_log: false
supported_decisions_types:
  - ban
#to change log prefix
deny_log_prefix: "crowdsec: "
#to change the blacklists name
blacklists_ipv4: crowdsec-blacklists
blacklists_ipv6: crowdsec6-blacklists
#if present, insert rule in those chains
iptables_chains:
  - INPUT
#  - FORWARD
  - DOCKER-USER

## nftables
nftables:
  ipv4:
    enabled: true
    set-only: false
    table: crowdsec
    chain: crowdsec-chain
  ipv6:
    enabled: true
    set-only: false
    table: crowdsec6
    chain: crowdsec6-chain
# packet filter
pf:
  # an empty string disables the anchor
  anchor_name: ""
```
You can safely ignore the `nftables` and `pf` sections of the config. They refer to firewall solution that we're not using in this setup.
===

Save your edits and quit nano, then run `systemctl restart crowdsec-firewall-bouncer` to apply your changes, followed by `systemctl status crowdsec-firewall-bouncer` to make sure its both running and healthy. Finally, run `iptables -L DOCKER-USER` and `ip6tables -L DOCKER-USER`, each time checking that a `crowdsec-blacklists` rule has been applied. The name differs slightly between `ip` and `ip6`.

```!#4,10
$ iptables -L DOCKER-USER
Chain DOCKER-USER (1 references)
target     prot opt source               destination
DROP       all  --  anywhere             anywhere             match-set crowdsec-blacklists src
RETURN     all  --  anywhere             anywhere

$ ip6tables -L DOCKER-USER
Chain DOCKER-USER (0 references)
target     prot opt source               destination
DROP       all      anywhere             anywhere             match-set crowdsec6-blacklists src
```

That's it. CrowdSec now runs in the background, monitoring your SSH logs, and will automatically ban all IPs that try to bruteforce that and any other service you connect in the future. 

## Useful Commands

- Run `cscli metrics` to get an overview of the processed files, how often failed logins were detected, how often these caused bans (called "overflow") and some other useful statistics
- Run `cscli alerts list` to see all the recent bans
- Use `cscli decisions list` to see the **currently active** bans
  - If you want to manually add an IP to ban, use `cscli decisions add <IP>` to do so. The commands' help page reveals additional options for range and duration.