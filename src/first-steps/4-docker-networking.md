---
visibility: hidden
---
<!-- this is currently a dummy file -->

# Networking in Docker

things to explain: 

- what do docker networks actually do
- example: app with frontend and database, only adding the frontend to the nginx network, with a separate net for app <-> db connection
- never open ports on new apps
- never address containers with their internal IP and instead always use the container name
- pay attention to not run additional proxies, which is part of the config on some larger apps