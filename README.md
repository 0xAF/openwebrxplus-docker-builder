# openwebrxplus-docker-builder
OpenWebRX+ docker images builder.  
Use this repo to build the official docker image and the SoftMBE image.  
The SoftMBE will use codecserver-softmbe (mbelib), enabling DMR, D-Star, YSF, FreeDV, DRM, NXDN and other Digital modes.

# Docker Hub
Check the [Docker Hub](https://hub.docker.com/r/slechev/openwebrxplus) page for the official image.  
Check the [Docker Hub](https://hub.docker.com/r/slechev/openwebrxplus-softmbe) page for the softmbe image.

# Install
See the [info of the official image](https://hub.docker.com/r/slechev/openwebrxplus).

# Reverse proxy setup

Running the container in combination with a reverse proxy to allow public access.

The software can show the real ip address of the client connecting and also has the ability to ban misuse.
For this to work in its current state one needs to add a nginx reverse proxy configuration to the compose file.
Below the relevant configuration. that will enable the OpenWebRX+ service on tcp port 8074.

docker-compose.yml

```
services:
  owrx:
    image: 'slechev/openwebrxplus-softmbe:latest'
    container_name: owrx-mbe
    restart: unless-stopped
    ports:
      - '8073:8073'
    environment:
      TZ: <your timezone>
      OPENWEBRX_ADMIN_USER: admin
      OPENWEBRX_ADMIN_PASSWORD: <your password>
    devices:
      - /dev/bus/usb:/dev/bus/usb
    volumes:
      - ${HOME}/compose/owrx-docker/etc:/etc/openwebrx
      - ${HOME}/compose/owrx-docker/var:/var/lib/openwebrx
      - ${HOME}/compose/owrx-docker/htdocs/static/css:/usr/lib/python3/dist-packages/htdocs/static/css
      - ${HOME}/compose/owrx-docker/plugins:/usr/lib/python3/dist-packages/htdocs/plugins
    # mount /tmp in memory, for RPi devices, to avoid SD card wear and make dump1090 work faster
    tmpfs:
      - /tmp:mode=1777

  nginx:
    image: nginx:stable
    container_name: nginx
    ports:
      - 8074:80
    tty: true
    stdin_open: true
    volumes:
      - ${HOME}/compose/owrx-docker/etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf
```

default.conf

```
server {
    listen 80;
    server_name websdr.example.com;

    location / {
        proxy_pass http://owrx-mbe:8073; # Local OpenWebRX address
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }
}
```
