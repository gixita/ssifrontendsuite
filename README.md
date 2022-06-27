<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

# Introduction
This repo contains :
- This mobile wallet developped by Elia Group is using the API of Energy Web Fundation : https://github.com/energywebfoundation/ssi/
- The Vendor portal to issue verifiable credentials
- The backend of the vendor portal

## Domains

ssiportal.eliagroup.io => Vendor portal
ssiportal.eliagroup.io => Vendor portal backend

# Installation
## General installation
```
apt install fail2ban
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 'Nginx Full'
ufw enable
apt install nginx
apt install sqlite3 libsqlite3-dev

```
On the server home folder create a few directories
```
- ssiserver/server
- ssiserver/frontend
- ssiserver/apkfiles
```

In ssiserver/server, create a file .env containing : 
```
AUTH_SECRET_KEY=65489151351981
AUTH_ISSUER=elia
```
Change the secret key above

## Build of the tools

- Install Flutter on your machine
- Change the global var to point to ssiportal-api.eliagroup.io (lib/glovalvar.dar)
- Use persistent storage change in `lib/sql_helper.dart` 
`static Future<SQLiteWrapper> db({inMemory = true, String? path})`
to 
`static Future<SQLiteWrapper> db({inMemory = false, String? path})`

### Portal server

- Build the tool from the directory portalserver with 
`dart compile exe bin/server.dart`
- Rename `server.exe` to `server`
- Copy the `server.exe` file to `ssiserver/server`
- Make the file executable `chmod +x server`

If your deamon is already running:
- Stop the deamon
`sudo systemctl stop ssiserver.service`
- Copy the server file
- Make it executable
- Restart the deamon
`sudo systemctl start ssiserver.service`
- Reload Nginx
`sudo systemctl reload nginx`

#### Make a deamon
- Create a configuration file : 
`sudo vim /etc/systemd/system/ssiserver.service`
- Copy the following
```
[Unit]
Description=Vendor portal server
[Service]
User=azureuser
#Code to execute
#Can be the path to an executable or code itself
WorkingDirectory=/home/azureuser/ssiserver/server
ExecStart=/home/azureuser/ssiserver/server/server
Type=simple
TimeoutStopSec=10
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
```
- Start the service
`sudo systemctl start ssiserver.service`
- Check if it is working
`sudo systemctl status ssiserver.service`
- Make the deamon start on startup
`sudo systemctl enable ssiserver.service`



### Portal frontend
- In the source folder `portalfrontend` run
`flutter build web`
- Copy all the files from `portalfrontend/build/web` into the server `ssiserver/frontend`

### Mobile wallet
- In the source folder `mobilessiwallet` run
`flutter build apk --split-per-abi`
- Copy the apk file `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` to the server `ssiserver/frontend`

## Configure Nginx
- Create a first file called
`/etc/nginx/sites-available/ssiserver`
- Create a symbolic link of the file
`sudo ln -s /etc/nginx/sites-available/ssiserver /etc/nginx/sites-enabled/ssiserver`
- Copy the following in `/etc/nginx/sites-available/ssiserver`

- Test the configuration with a dry-run
`sudo nginx -t -c /etc/nginx/sites-available/ssiserver`

- Create a second file
`/etc/nginx/sites-available/ssiserverapi`
- Create a symbolic link of the file
`sudo ln -s /etc/nginx/sites-available/ssiserverapi /etc/nginx/sites-enabled/ssiserverapi`
- Copy the following in `/etc/nginx/sites-available/ssiserverapi`

- Test the configuration with a dry-run
`sudo nginx -t -c /etc/nginx/sites-available/ssiserverapi`

- Reload Nginx 
`sudo systemctl reload nginx`

## Get the TLS certificates
sudo certbot --nginx -d ssiportal-api.eliagroup.io
sudo certbot --nginx -d ssiportal.eliagroup.io

Use this Nginx configuration
```
server {
        server_name ssiportal-api.eliagroup.io;
        #return 301 https://$host:443$request_uri;
    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/ssiportal-api.eliagroup.io/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/ssiportal-api.eliagroup.io/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
        client_max_body_size 0;
underscores_in_headers on;
location ~ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header Front-End-Https on;
        proxy_headers_hash_max_size 512;
        proxy_headers_hash_bucket_size 64;
        proxy_buffering off;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        proxy_pass http://127.0.0.1:8080;
}}

server {
    if ($host = ssiportal-api.eliagroup.io) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


        listen 80;
        listen [::]:80;
        server_name ssiportal-api.eliagroup.io;
    return 404; # managed by Certbot
}

server {
        server_name ssiportal.eliagroup.io;
        #return 301 https://$host:443$request_uri;
    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/ssiportal.eliagroup.io/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/ssiportal.eliagroup.io/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
        client_max_body_size 0;
        underscores_in_headers on;
        root /home/azureuser/ssiserver/frontend;
        index index.html index.htm;

location ~ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header Front-End-Https on;
        proxy_headers_hash_max_size 512;
        proxy_headers_hash_bucket_size 64;
        proxy_buffering off;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        try_files $uri $uri/ =404;
}
location = /mobilewallet.apk {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header Front-End-Https on;
        proxy_headers_hash_max_size 512;
        proxy_headers_hash_bucket_size 64;
        proxy_buffering off;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        try_files /app-arm64-v8a-release.apk $uri/ =404;
}
}

server {
    if ($host = ssiportal.eliagroup.io) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
        listen 80;
        listen [::]:80;
        server_name ssiportal.eliagroup.io;
    return 404; # managed by Certbot
}
```
