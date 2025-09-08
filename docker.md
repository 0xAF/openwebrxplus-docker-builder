# [OpenWebRX+ Docker Image](https://github.com/luarvique/openwebrx)

Built from [.deb packages](https://luarvique.github.io/ppa/) of [Marat's (luarvique) fork](https://github.com/luarvique).

---

## 🚨 Support & Issues

For issues with this image, contact [LZ2SLL](https://0xaf.org/about/) or join the [OpenWebRX+ chat](https://t.me/openwebrx_chat).

---

## Features

- All receivers and demodulators included
- Health checks for service and SDR devices
- Easy admin user setup
- Plugin extension support

---

## Usage

For detailed features and troubleshooting, see the [OpenWebRX+ Info Page](https://fms.komkon.org/OWRX/).

---

### Timezone Configuration

Set the `TZ` environment variable to your timezone (e.g., `Europe/Sofia`).  
[List of timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)

---

### Port Forwarding for rtl_tcp

By default, rtl_tcp-compatible data ports bind to localhost inside the container. To expose these ports:

1. Set `FORWARD_LOCALPORT_XXXX=YYYY` as an environment variable, where:
   - `XXXX` = internal port, the one you setup in OWRX settings page (e.g. 1234)
   - `YYYY` = external port, the one you want exposed in your network (e.g. 5678)
   - Both must be different.
2. Add `-p YYYY:YYYY` to your `docker run` command.

---

### Admin User Setup

Set these environment variables to create an admin user:

- `OPENWEBRX_ADMIN_USER=myuser`
- `OPENWEBRX_ADMIN_PASSWORD=password`

---

### Container Health Checks

The container includes a health check script:

- **Port Check:** Always checks if port 8073 is open and OWRX responds.
- **USB Device Check:**  
  Set `HEALTHCHECK_USB_<VENDOR>_<PRODUCT>=N` to require N devices with the given USB IDs.
- **SDR Device Check:**  
  Set `HEALTHCHECK_SDR_DEVICES=N` to require N SDR devices to be running inside OWRX.

Use [autoheal](https://hub.docker.com/r/willfarrell/autoheal/) to restart unhealthy containers.

---

## Installation

```sh
# Create persistent data directories
mkdir -p /opt/owrx-docker/var /opt/owrx-docker/etc /opt/owrx-docker/plugins/receiver /opt/owrx-docker/plugins/map

# Run the container
docker run -d --name owrxp \
    --device /dev/bus/usb \
    --tmpfs=/tmp \
    -p 8073:8073 \
    -p 5678:5678 \
    -v /opt/owrx-docker/var:/var/lib/openwebrx \
    -v /opt/owrx-docker/etc:/etc/openwebrx \
    -v /opt/owrx-docker/plugins:/usr/lib/python3/dist-packages/htdocs/plugins \
    -e TZ=Europe/Sofia \
    -e FORWARD_LOCALPORT_1234=5678 \
    -e OPENWEBRX_ADMIN_USER=myuser \
    -e OPENWEBRX_ADMIN_PASSWORD=password \
    -e HEALTHCHECK_USB_0BDA_2838=2 \
    -e HEALTHCHECK_SDR_DEVICES=4 \
    --restart unless-stopped \
    slechev/openwebrxplus-softmbe
```

---

## Docker Compose Example

Save as `/opt/owrx-docker/docker-compose.yml`:

```yaml
services:
  owrx:
    image: 'slechev/openwebrxplus-softmbe:latest'
    container_name: owrx-mbe
    restart: unless-stopped
    ports:
      - '8073:8073'
      - '5678:5678'
    environment:
      TZ: Europe/Sofia
      FORWARD_LOCALPORT_1234: 5678
      OPENWEBRX_ADMIN_USER: myuser
      OPENWEBRX_ADMIN_PASSWORD: password
      HEALTHCHECK_USB_0BDA_2838: 2
      HEALTHCHECK_USB_0BDA_2832: 1
      HEALTHCHECK_USB_1DF7_3000: 1
      HEALTHCHECK_SDR_DEVICES: 4
    devices:
      - /dev/bus/usb:/dev/bus/usb
    volumes:
      - /opt/owrx-docker/etc:/etc/openwebrx
      - /opt/owrx-docker/var:/var/lib/openwebrx
      - /opt/owrx-docker/plugins:/usr/lib/python3/dist-packages/htdocs/plugins
    # mount /tmp in memory, for RPi devices, to avoid SD card wear and make dump1090 work faster
    tmpfs:
      - /tmp:mode=1777

# if you want your container to restart automatically if the HEALTHCHECK fails
# (see here: https://stackoverflow.com/a/48538213/420585)
  autoheal:
    restart: always
    image: willfarrell/autoheal
    environment:
      - AUTOHEAL_CONTAINER_LABEL=all
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

- Edit as needed.
- Start with: `docker compose up -d`

---

## Plugins

Add plugins under `/opt/owrx-docker/plugins/[receiver|map]`.  
See [plugin instructions](https://github.com/0xAF/openwebrxplus-plugins).

```sh
# create init.js from the sample
wget -O /opt/owrx-docker/plugins/receiver/init.js https://raw.githubusercontent.com/0xAF/openwebrxplus-plugins/main/receiver/init.js.sample
wget -O /opt/owrx-docker/plugins/map/init.js https://raw.githubusercontent.com/0xAF/openwebrxplus-plugins/main/map/init.js.sample
```

---

## Blacklisting Device Drivers (Host)

To avoid conflicts, blacklist SDR drivers on the host and reboot:

```sh
cat > /etc/modprobe.d/owrx-blacklist.conf << _EOF_
blacklist dvb_usb_rtl28xxu
blacklist sdr_msi3101
blacklist msi001
blacklist msi2500
blacklist hackrf
_EOF_
```

---

## SDRPlay Devices

If SDRPlay devices are not detected after first run, restart the container.  
See [official wiki](https://github.com/jketterl/openwebrx/wiki/SDRPlay-device-notes#no-sdr-devices-available-when-running-in-docker) and [docker-usb-sync](https://github.com/pbelskiy/docker-usb-sync) for more info.

---

## Need Help?

- [OpenWebRX+ Info](https://fms.komkon.org/OWRX/)
- [GitHub Issues](https://github.com/0xAF/openwebrxplus-docker-builder/issues)

---

## More Information

- [Getting Started with Docker](https://github.com/jketterl/openwebrx/wiki/Getting-Started-using-Docker)
- [User Management](https://github.com/jketterl/openwebrx/wiki/User-Management#special-information-for-docker-users)
- [Docker Image Builder](https://github.com/0xAF/openwebrxplus-docker-builder)
