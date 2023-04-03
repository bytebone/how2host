---
label: "Reverse Proxy"
order: 30
---

!!!warning
This is a content skeleton, and not yet properly written out.
!!!

## What does a Reverse Proxy do? 


- allows you to access any of your apps with a subdomain or subdirectory on your domain.
- eliminates requirement to open ports for different apps (with exceptions)
- allows fine grained control over which traffic moves in and out of your server

## Common Errors when using a reverse proxy

- Exposing ports of applications even though you access them through a browser
- not locking down your server to only take requests from the cloudflare proxy
- not using proper encryption between reverse proxy and cloudflare

## Which Reverse Proxy should I use?

- common ones are Nginx, Nginx Proxy Manager, Traefik and Caddy
- list some pros and cons of each, shortly describing
- guides are usually written with npm in mind, since its easy to use and setup

[!ref](./nginx.md)
[!ref Traefik **(External link)**](./traefik.md)
[!ref Caddy **(External link)**](./caddy.md)