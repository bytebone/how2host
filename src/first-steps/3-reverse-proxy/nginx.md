---
# author: rainer
order: 1 #remove this once the other reverse proxy guides are done
---
# Nginx

[!ref Official Docs](https://nginxproxymanager.com/guide/#quick-setup)

## Installation with Docker Compose

Nginx is a reverse proxy, which we will use to direct traffic on your domain name to the different services on your server. Since the classic Nginx is entirely configured in text files, we will be using an extension called "Nginx Proxy Manager" or "NPM" for short. It automates the creation of your config files with an easy-to-use web interface and allows for a fast and easy overview and management of your hosts.

To get started with the Nginx setup, create a new folder at any location you please. As an example, we're going to use `mkdir -p /home/docker/nginx`, followed by `cd /home/docker/nginx`. Now, run `nano compose.yml` and paste the following code:

```yml compose.yml
services:
	nginx:
		image: jc21/nginx-proxy-manager:latest
		container_name: nginx 
		restart: always
		ports:
			- 80:80
			- 81:81
			- 443:443
		environment:
			DB_MYSQL_HOST: db
			DB_MYSQL_PORT: 3306
			DB_MYSQL_USER: npm
			DB_MYSQL_PASSWORD: <random string 1>
			DB_MYSQL_NAME: npm
		volumes:
			- data:/data
			- data:/etc/letsencrypt
        networks:
          - default
          - internal
		depends_on:
			- db

	db:
		image: mariadb
		container_name: nginx-db
		restart: always
		command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW --innodb-file-per-table=1 --skip-innodb-read-only-compressed
		volumes:
			- db:/var/lib/mysql
        networks:
          - internal
		environment:
			- MYSQL_ROOT_PASSWORD=<random string 2>
			- MYSQL_PASSWORD=<random string 1>
			- MYSQL_DATABASE=npm
			- MYSQL_USER=npm

networks:
	default:
  internal:

volumes:
	db:
	data:
```

 A short explanation of this script:
 
 - The `services` section defines both the actual Nginx app, as well as the database used to store data.
   - You need to generate two random strings as passwords, for example using the command `openssl rand -base64 20`, and put them in the appropriate spots. Make sure that the password matches in the two places using `<random string 1>`! 
   - For now, we will expose both port 80 and 81, which are unsecure ports that we will close down later.
   - The `container_name` property manually defines the name, since the auto generated names are long and ugly. We will need to enter this into the Nginx interface in a minute!
 - The `networks` section defines two networks. The `default` network allows you to expose services to the internet, and the `internal` network connects exclusively Nginx to its database.
 - The `volumes` section defines two volumes, which are storage locations for persistent data, since a container will be deleted with all its included data whenever you stop or restart it.

As you've done before, exit nano and save your changes. Once you've left nano, run `docker compose up` to download and start Nginx with its components. Once the logs mention a successful startup, open your browser and enter into the address bar `<your server ip>:81`. This should bring up the NPM login screen. The login credentials are `admin@example.com` and `changeme` as the password. You will be prompted to create a new password immediately.

Once logged in, navigate to the green "Proxy Hosts" section, click "Add Proxy Host" in the top right, and enter the following details:

- **Domain Names:** `proxy.your.domain` (replace `your.domain` with your actual domain)
- **Forward Hostname:** nginx (the name of the container in your Compose file)
- **Port:** 81
- **Toggle Common Exploits:** On

Press Save, then click on the domain name in your list. The URL will open in a new tab and should load you right into the NPM interface. **This should have been the last time you ever access the server with its IP instead of a domain.** 

## Enforcing encryption between your server and Cloudflare

[!ref Official Docs](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/)

!!!info
Should you have decided to not use Cloudflare as your proxy, this section does not apply to you. You can generate a LetsEncrypt wildcard certificate instead and use that to serve encrypted data to your visitors.
!!!

In the current setup, your server sends unencrypted content to the Cloudflare proxy, which then encrypts it locally and forwards it to the person accessing your website. This is bad, because anyone could intercept, read and modify the data before it reaches Cloudflare, as well as read all the traffic sent back to your server. 

To lock this down, go to the `Cloudflare Dashboard > Your Website > SSL/TLS > Origin Server`, click on `Create Certificate`, confirm that the hostnames are both `*.your.domain` and `your.domain`, decrease the validity to a more sensible 2 years if desired, and confirm. After a short pause, you will get two text boxes with random-looking strings in them. You need to copy the contents of both and paste them into two files on your local machine. The content of `Private Key` should be saved into a file called `cert.key`, and the content of `Origin Certificate` into a file called `cert.pem`. You can do this with any text editor, even notepad. Just make sure the file extension matches!

Once you saved them, open your Nginx dashboard, switch to `SSL Certificates` and `Add SSL Certificate > Custom`. You cannot change the name later, so I recommend calling it `CF <your domain>`, in case you'll be hosting multiple domains from this server - this happens faster than you think! For the key, upload your `cert.key`, and for the certificate your `cert.pem`, and save the certificate.

Now, switch back to the Proxy Hosts tab. Edit your Nginx entry, change to the SSL Tab, and select your newly added certificate. Also, toggle the "Force SSL" switch - the others don't do much in your use case.

To finish this step, go back to your Cloudflare Dashboard, switch to `SSL/TLS > Overview`, and at the very top, set the encryption mode to `Full (Strict)`. This ensures that only traffic that has been encrypted with the specific certificate will be accepted by Cloudflare, providing maximum security for you and any other visitors of your pages.

If your Nginx dashboard still loads fine after this change, you've done it. From now on, every little bit of traffic will be running over the encrypted port 443, so we can close the other ports still opened by Nginx. To do so, go back into the terminal, where the Nginx container should still be running in the foregound. Press `CTRL+C` to quit it, then `nano compose.yml` to get back into the config file. Find and remove the two lines with which Nginx exposes the ports 80 and 81.

```yml #7-8 compose.yml
services:
	nginx:
		image: jc21/nginx-proxy-manager:latest
		container_name: nginx 
		restart: always
		ports:
			- 80:80
			- 81:81
			- 443:443

< --- >

networks:
	default:
    internal:

volumes:
	db:
	data:
```

Exit and save out of nano, then run `docker compose up -d` to start Nginx again, but this time in the background. Reload the Nginx website to make sure it's running and working, and run `lsof -Pni | grep docker` in your terminal to confirm that only port 443 is opened.

## Important information for future apps
<!-- This section is a partial duplicate with ./readme.md -->

Many people get confused about if or how to handle their ports. When setting up apps, many documentations tell you to open ports in the Docker Compose script. This is entirely unneeded when running a reverse proxy, and will only cause issues.

Remember, **you do not need to open any ports** to make a service accessible to Nginx and therefore the open internet. Just add the new container to your nginx network (i.e. `nginx_default`), note the required port and enter both container name and port in the Nginx web interface when creating the host.

Similarly, instead of using IP addresses to refer to hosts, always use the container name, which Docker automatically resolves. This applies to Nginx hosts and apps accessing other services, for example a separated database container.