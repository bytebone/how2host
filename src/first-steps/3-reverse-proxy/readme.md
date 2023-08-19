---
label: "Reverse Proxy"
order: -3
---

## What does a Reverse Proxy do? 

A reverse proxy connects an app running locally on your server to a web address through subdomains (`my-app.example.com`) or subdirectories (`example.com/my-app`). This keeps your links clean and connections secure, since you no longer need to open server ports for accessing apps.

If you wanted to skip the reverse proxy, you would access your services through links with portnumbers, like `example.com:8000`. This approach would also be very cumbersome, if not impossible to setup when using Cloudflare.

## Common Mistakes

⚠ **Exposing ports of applications in your Docker Compose files:** Many official setup guides for apps include a section in their compose file that would open external ports for app access. These sections should **always be removed**, unless you know exactly what you're doing.

⚠ **Not using proper encryption between your server and Cloudflare:** When using the Cloudflare proxy, all your traffic is sent from your server to Cloudflare, who pass it on to your users. To make sure that no one can intercept, read or manipulate the datastream between your and Cloudflares server, the data should be encrypted using a CF-generated certificate, and Cloudflare should be set to refuse any connection that is not encrypted with this certificate. 

## Which one should I use?

There are a bunch of options, which all vary in how they're set up and used. These are the most common ones.

### <a href="https://nginxproxymanager.com/guide/" target="_blank">Nginx Proxy Manager</a>
A frontend for the popular Nginx proxy, allowing control of your hosts through a slick web interface.

!!!contrast
Many guides are currently written with this proxy in mind. While any of the apps will also work with any other proxy, you will require research outside this wiki to make it work.

**Beginners should use this for an easy start.** Rewriting the guides to be proxy-agnostic is planned.
!!!

| Pro | Con |
|---|---|
| <ul><li>Battle-tested proxy over many years</li><li>Comfortable usage in web UI</li><li>Hassle-free configuration of SSL certificates</li> </ul> | <ul> <li>High RAM usage compared to other options</li> </ul> |

[!ref](./nginx.md)

### <a href="https://doc.traefik.io/traefik/" target="_blank">Traefik</a>
A proxy designed for servers with many apps, controlled through code right in your Docker Compose files.

| Pro | Con |
|---|---|
| <ul><li>Built from the ground up for this use-case</li><li>Configuration of your apps and the proxy is in one place - the Compose file</li> </ul> | <ul> <li>The configuration syntax is not easy to remember</li> </ul> |

[!ref Traefik **(External Link)**](./traefik.md)

### <a href="https://caddyserver.com/docs/quick-starts/reverse-proxy" target="_blank">Caddy</a>

Once just a webserver, Caddy has evolved into a fast proxy that has an incredibly easy configuration syntax and uses ridiculously little ressources. 

| Pro | Con |
|---|---|
| <ul><li>Easy configuration with Caddyfiles and easy syntax</li><li>No-Fuss proxy with high speeds and performance</li> </ul> | <ul> <li>Doesn't scale well when hosting many services</li> </ul> |

[!ref Caddy **(External Link)**](./caddy.md)

!!!success Interested in some tinkering?
Caddy isn't ideal for a server with many apps running in parallel, but there are community efforts to transform it into something that works more like Nginx - **a singular instance controlling all traffic and internally redirecting to the correct target**. 

This project combines the performance and easy configuration of Caddy with the "configuration-in-compose" approach from Traefik. While the How2Host authors have not yet tested this, it may be promising to the adventurous. 

[!button target="blank" icon="link-external" text="Check it out"](https://github.com/lucaslorentz/caddy-docker-proxy)
!!!

### <a href="https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/" target="_blank">Cloudflare Tunnels</a>

Runs as a daemon on your server and is entirely controlled in the CF Dashboard you already use.

| Pro | Con |
|---|---|
| <ul><li>Automatically handles encryption between your server and Cloudflare</li><li>Zero-Maintenance on your server</li><li>Tiny RAM footprint</li> </ul> | <ul> <li>Official Documentation is hard to understand</li> </ul> |

[!ref Cloudflare Tunnels **(External Link)**](./cf-tunnels.md)
