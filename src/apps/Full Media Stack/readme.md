---
# author: Alino001           # Add as comment, in case we want to display authors down the road
# order: 40                 # Uncomment in case a specific position is desired. Higher number > earlier position
category: [Media]    # Add app categories you seem fit. Not yet standardized.
icon: video   # Add an icon from https://primer.github.io/octicons that fits the app / stack
---

# Full Media Stack

[!ref Official Docs](https://zerodya.net/self-host-jellyfin-media-streaming-stack/)

## Prerequisites

[!ref icon="check-circle" text="First Steps"](../../first-steps/2-docker-setup.md)

## Information about "Full Media Stack"

A Full Media Stack is a collection of programs for watching movies and TV shows. By hosting one, you can enjoy watching your media collection without concerns about privacy or availability.

These are the programs we are going to use:

=== Radarr
Manages movies and sends requests to Jackett

=== Sonarr
Manages TV shows (and anime) and sends requests to Jackett

=== Jackett
Parses the results coming from Radarr 

=== Transmission
Torrent client to download all media

=== Jellyfin
Streams media from the server to different clients

=== Jellyseerr
Webapp for the User to discover and request movies and TV shows

=== Bazarr
Scans avaliable media and downloads subtitles for it
===


## Creating the containers

The long list of containers can be split into two categories: apps that manage the acquisition of your media, and apps that manage the streaming of your collected media. To make this separation easy to manage, you need to create two folders, one called "Streaming stack" and one called "Downloading stack".

The "Streaming stack" includes Jellyfin, Radarr, Sonarr, Bazzarr and Jellyseerr while the "Downloading stack" includes Jackett and Transmission. 

In one folder after another, create your `compose.yml` and copy the respective contents from down below:

!!! 
Make sure to adjust the timezone in the highlighted lines to match your local timezone.
!!!

### Streaming Stack

```yml #9,25,41,56,73 compose.yml
version: "3"
services:
  jellyfin:
    image: jellyfin/jellyfin
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Rome
    volumes:
      - ./jellyfin_config:/config
      - /media/tvshows:/data/tvshows
      - /media/movies:/data/movies
      - /media/anime:/data/anime
    ports:
      - 8096:8096
    restart: unless-stopped

  sonarr:
    image: linuxserver/sonarr
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Rome
    volumes:
      - ./sonarr_config:/config
      - /media/anime:/anime
      - /media/tvshows:/tvshows
      - /media/transmission/downloads/complete:/downloads/complete
    ports:
      - 8989:8989
    restart: unless-stopped

  radarr:
    image: linuxserver/radarr
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Rome
    volumes:
      - ./radarr_config:/config
      - /media/transmission/downloads/complete:/downloads/complete
      - /media/movies:/movies
    ports:
      - 7878:7878
    restart: unless-stopped

  bazarr:
    image: linuxserver/bazarr
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Rome
    volumes:
      - ./bazarr_config:/config
      - /media/movies:/movies #optional
      - /media/tvshows:/tvshows #optional
      - /media/anime:/anime
    ports:
      - 6767:6767
    restart: unless-stopped

  jellyseerr:
    image: fallenbagel/jellyseerr:develop
    container_name: jellyseerr
    environment:
      - PUID=1000
      - PGID=1000
      - LOG_LEVEL=debug
      - TZ=Europe/Rome
    ports:
      - 5055:5055
    volumes:
      - ./jellyseerr_config:/app/config
    restart: unless-stopped
    depends_on:
      - radarr
      - sonarr
```
### Downloading Stack

```yml docker-compose.yml
version: "2.1"
services:
  jackett:
    image: linuxserver/jackett
    container_name: jackett
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Rome
      - AUTO_UPDATE=true #optional
    volumes:
      - ./jackett:/config
      - /media/jackett/downloads:/downloads
    ports:
      - 9117:9117
    restart: unless-stopped

  transmission:
    image: linuxserver/transmission
    container_name: transmission
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Rome
    volumes:
      - ./transmission:/config
      - /media/transmission/downloads:/downloads
    ports:
      - 9091:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped
```

After that, run `docker compose up -d` to install and launch the containers in the background. Remember to take a screenshot of the Ports, you need them later. Now you only need to make auser to UID/GID 1000 so you can modifiy the files, you can do that with these commands: ``groupadd -g 1000 dockeruser && useradd dockeruser -u 1000 -g 1000 -s /bin/bash`` and ``chown -R dockeruser:dockeruser /*the directory*/streaming-stack /*the directory*/downloading-stack /media``


## Configuration

### Jellyfin

1.  Open your web browser and type in the IP address of your Jellyfin server followed by port 8096 (e.g. 192.168.1.100:8096).
2.  You will be directed to the Jellyfin setup tour. Fill in the required information such as the language and the user. Skip the "Media Library" step and continue by clicking "Next" on the following prompts.
3.  After completing the setup tour, login and go to the Dashboard where you can configure Jellyfin.
    - By clicking on "Users", you can create additional account for your family and friends.
5.  Go to "Library" and click on "Add Media Library". Choose "Movies" and select the folder ``/data/movies``. Then, choose your preferred language (e.g English)
6.  Repeat step 5 but instead of "Movies", choose "Shows". In the Shows Library, choose the folder ``/data/tvshows``.
    - You can also create an Anime Library and choose the ``/data/anime`` folder.


### Jackett

1. Open your web browser and type in the IP address of your Jackett server followed by port 9117 (e.g. 192.168.1.100:9117).
2. Click on "Add Indexer".
3. Choose your preferred indexers by clicking on the "+" button and editing them to your choices.
!!! 
Make sure your indexes are the same of your Language (e.g en_US), you can also choose diffrent ones (e.g en_US **and** en_UK)
!!!
4. Optional: Add an Admin Password.

### Sonarr/Radarr

!!!contrast Warning
Radarr and Sonarr are related to each other, so the setup process for both is identical. You can therefor repeat these steps twice, once for Radarr, once for Sonarr.
!!!

1. Open your web browser and type in the IP address of your Sonarr server followed by port 8989 (e.g. 192.168.1.100:8989).
2. Go to "Settings" and then "Download Clients".
3. Click on the big "+" button to create a download client, and enter the following values:
    - Choose Transmission
    - Name: Transmission
    - Enable: Yes
    - Static IP: *Your Static IP*
    - Port: 9091
4. Save and go back to the "Settings", then "Indexers" and click the big "+" button to add an indexer. Choose "Torznab". Make your name "1337x" and the URL should be your Torznab feed URL and the API key the Jackett API key, both of which you can find in Jackett. Choose your categories and optional anime categories. Repeat this step for every index you added in Jackett.
5. Go back to "Settings", then "Media Management", and click "Add Root Folder". Add /anime and /tvshows for Sonarr and /movies for Radarr.


### Jellyseerr

1. Open your web browser and type in the IP address of your Jellyseerr server followed by port 5055 (e.g. 192.168.1.100:5055).    
2. You will be directed to the Jellyseerr setup tour, starting by creating your account.
3. Press the "Sync Libraries" button. The libraries you added in Jellyfin should appear, so select all of them.
4. In the final section, you will be asked to add both a **Radarr** and a **Sonarr** server. Configure **Radarr** like this: 
    - Default Server: On 
    - Name: Radarr 
    - IP: *your IP* 
    - Port: 7878
    - API KEY: (You can find it in Settings -> General) (e.g 192.168.1.100:7878)
    - Quality: HD
    - Root: /movies 
5. (Optional) After setting up the quick setup tour, add the users from Jellyfin, set the language (Settings, General), and the user permissions (Settings, Users).

### Bazarr
To set up Bazarr, follow these steps:

1. Open your web browser and type in the IP address of your Bazarr server followed by port 6767 (e.g. 192.168.1.100:6767).
2. Add Sonarr's and Radarr's API Key. You can find the API keys in Settings -> General in both Sonarr and Raddar. Add the keys in Bazarr in Settings -> Sonarr and Settings -> Radarr. Make the address your IP, the port to Sonarr/Radarr's port, and the Base URL /.
3. Go to Settings, Providers, click on the big "+" button, and choose a provider. I recommend OpenSubtitles.org.
4. Enable subtitles via Settings > Languages.
5. Go to "Default Settings" and choose what you want to have subtitles.

## Final Thoughts 

You are done setting up a Full Media Stack! Have fun watching your favorite Movie, TV Show or Anime!

