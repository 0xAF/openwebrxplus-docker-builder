# OpenWebRX+ Docker Compose installation and configuration

This GitHub repository is the primary documentation for the
[`slechev/openwebrxplus`](https://hub.docker.com/r/slechev/openwebrxplus) and
[`slechev/openwebrxplus-softmbe`](https://hub.docker.com/r/slechev/openwebrxplus-softmbe)
images, built from [Marat's OpenWebRX+ Debian packages](https://luarvique.github.io/ppa/).
Docker Compose is the supported installation and deployment method.

- [Quick start](#quick-start)
- [Choosing an image](#choosing-an-image)
- [Verify the installation](#verify-the-installation)
- [Configuration reference](#configuration-reference)
- [USB passthrough and reconnection](#usb-passthrough-and-reconnection)
- [Container health checks](#container-health-checks)
- [Updating the container](#updating-the-container)
- [Backup and restore](#backup-and-restore)
- [Plugins](#plugins)
- [Blacklisting device drivers](#blacklisting-device-drivers-host)
- [Troubleshooting](#troubleshooting)

## Quick start

Use a Linux host with Docker Engine, the Docker Compose plugin, and your SDR USB
receivers connected. Confirm that `docker compose version` works. On Windows
WSL2, first follow the Windows and USB setup instructions on the
[OpenWebRX+ Info Page](https://fms.komkon.org/OWRX/). The USB configuration below
assumes `/dev/bus/usb` is available on the Docker host.

The maintained deployment files are [compose.yaml](compose.yaml) and
[.env.example](.env.example). Download them to your installation directory
(use `sudo` for directory creation if required by your host):

```sh
mkdir -p /opt/owrx-docker/etc /opt/owrx-docker/var \
  /opt/owrx-docker/plugins/receiver /opt/owrx-docker/plugins/map
cd /opt/owrx-docker
curl -fL https://raw.githubusercontent.com/0xAF/openwebrxplus-docker-builder/main/compose.yaml -o compose.yaml
curl -fL https://raw.githubusercontent.com/0xAF/openwebrxplus-docker-builder/main/.env.example -o .env.example
cp .env.example .env
```

Edit `.env`: set `OPENWEBRX_ADMIN_PASSWORD` to your chosen password and adjust
`TZ`. The password starts empty, and Compose requires a non-empty value before
starting. Use single quotes around passwords containing `$` or `#`.
The default image is the standard variant; see [choosing an image](#choosing-an-image)
for SoftMBE.

Validate and start both OWRX and its autoheal companion:

```sh
docker compose config --quiet
docker compose up -d
```

Open `http://HOST:8073` (replace `HOST` with your server's hostname or IP). Sign in
to Settings with the admin credentials from `.env`, configure your SDR devices
and profiles, then select a receiver in the web interface. Allow startup to
complete before checking reception.

All Compose commands in this guide run from `/opt/owrx-docker`. To use another
installation directory, keep `compose.yaml`, `.env`, `etc`, `var` and `plugins`
together there. Data paths in the Compose file are relative to that file.

## Choosing an image

| Image | Choose it when |
| --- | --- |
| `slechev/openwebrxplus:latest` | You want the standard OpenWebRX+ receivers and included demodulators. This is the default. |
| `slechev/openwebrxplus-softmbe:latest` | You also want the SoftMBE decoder, for digital voice modes such as DMR, D-Star and YSF. It uses mbelib-neo v2 by default. |

The SoftMBE image extends the standard image. Both use the same Compose file,
USB configuration, admin setup, plugins and persistent directories. Reception
still requires the relevant SDR profile and decoder to be configured in OWRX.

To choose SoftMBE, change this line in `.env`:

```dotenv
OWRX_IMAGE=slechev/openwebrxplus-softmbe:latest
```

Then apply the image change:

```sh
docker compose pull owrx
docker compose up -d --no-deps owrx
```

Switch back by setting `OWRX_IMAGE=slechev/openwebrxplus:latest` and running the
same commands. Changing images briefly interrupts reception and retains the
mounted settings. For image builds and legacy mbelib options, see [README](README.md).

## Verify the installation

After configuring your receivers:

1. Run `docker compose ps`. OWRX should reach `healthy`; autoheal should be running.
2. Open the receiver page and select a configured SDR profile. Confirm that its
   waterfall updates and that you receive a known signal with the appropriate mode.
3. Open `http://HOST:8073/status.json` and confirm that the expected SDR sources
   appear in `sdrs`.
4. Set `HEALTHCHECK_SDR_DEVICES` in `.env` to the expected available source count,
   and optionally enable USB count checks in `compose.yaml`.
5. Apply those settings with `docker compose up -d` and check `docker compose ps`
   again.

A `healthy` container confirms only the checks you enabled. The default HTTP
check proves that OWRX responds. Neither USB enumeration nor the source count
check proves that IQ samples or a usable radio signal are arriving.

## Configuration reference

Compose reads `.env` next to `compose.yaml`. After changing either file, run
`docker compose config --quiet` and `docker compose up -d`. A plain
`docker compose restart` does not apply changed environment variables.

### Variables in `.env`

| Variable | Required | Default | Purpose / example |
| --- | --- | --- | --- |
| `OWRX_IMAGE` | No | `slechev/openwebrxplus:latest` | Image to deploy; use `slechev/openwebrxplus-softmbe:latest` for SoftMBE. |
| `OWRX_HTTP_PORT` | No | `8073` | Published web port on the host; the container still listens on 8073. |
| `TZ` | No | `Europe/Sofia` | Container timezone, e.g. `Europe/London`. |
| `OPENWEBRX_ADMIN_USER` | No | `admin` | Username to create on first setup. |
| `OPENWEBRX_ADMIN_PASSWORD` | Yes for this Compose template | Empty in `.env.example`; no fallback | Password for creating the admin user. |
| `HEALTHCHECK_SDR_DEVICES` | No | `0` (disabled) | Exact expected number of available OWRX sources, e.g. `3`. |

The admin variables create the user only if it does not already exist. Changing
them does not reset an existing user's password. The image itself allows these
variables to be omitted; the supplied Compose template requires a password to
make initial admin setup explicit.

### Optional variables in the `owrx.environment` section of `compose.yaml`

| Variable | Required | Default | Purpose / example |
| --- | --- | --- | --- |
| `HEALTHCHECK_USB_<VENDOR>_<PRODUCT>` | No | Not set (disabled) | Minimum USB device count for the given IDs, e.g. `HEALTHCHECK_USB_0BDA_2838: "2"`. |
| `FORWARD_LOCALPORT_XXXX` | No | Not set (disabled) | Forward container port `YYYY` to localhost port `XXXX`, e.g. `FORWARD_LOCALPORT_1234: "5678"`. |

The template contains commented examples. Add or uncomment these directly under
`owrx.environment`; adding an arbitrary variable only to `.env` does not pass it
into the container unless the Compose file references it.

For rtl_tcp forwarding, configure the internal port in OWRX, enable
`FORWARD_LOCALPORT_1234: "5678"`, and uncomment `"5678:5678"` in `owrx.ports`.
The internal and forwarded ports must differ.

### Persistent storage and ports

| Host path / port | Container destination | Contents / purpose |
| --- | --- | --- |
| `./etc` | `/etc/openwebrx` | Application configuration files. |
| `./var` | `/var/lib/openwebrx` | Receiver settings, user data and other persistent application state. |
| `./plugins` | `/usr/lib/python3/dist-packages/htdocs/plugins` | Receiver and map plugins. |
| `/dev/bus/usb` | `/dev/bus/usb` | Live USB device nodes from the host. |
| `OWRX_HTTP_PORT` | TCP 8073 | Web interface and status endpoints. |
| TCP 5678 (optional) | TCP 5678 | Example forwarded rtl_tcp port. |

`/tmp` uses a memory-backed temporary filesystem. Its contents are recreated on
container startup and are not part of a backup.

## USB passthrough and reconnection

The Compose configuration bind mounts `/dev/bus/usb` and allows USB character
devices with `device_cgroup_rules: ["c 189:* rwm"]`.
The bind mount exposes new device nodes after a dongle disconnects and reconnects;
the cgroup rule permits access even when its USB device number changes.

Using only `devices: /dev/bus/usb:/dev/bus/usb` can leave a running container with
stale device nodes after reconnection. Switching an SDR off and on in OWRX does
not refresh the container's device nodes.

When migrating an existing Compose installation, remove that `devices` mapping,
add the bind mount and cgroup rule from [compose.yaml](compose.yaml), and preserve
your existing persistent data paths. Then recreate the OWRX service:

```sh
docker compose config --quiet
docker compose up -d --no-deps --force-recreate owrx
```

Recreation briefly interrupts reception. The USB mapping does not fix physical
USB faults or guarantee that OWRX restarts a failed source automatically; use
SDR health checks and autoheal for recovery.

## Container health checks

The image includes three checks:

- **HTTP:** Always requests `http://localhost:8073/metrics` and checks that OWRX responds.
- **USB count:** Optional minimum device count for each configured vendor/product ID.
- **SDR source count:** Optional exact count of available sources in OWRX's
  `/status.json`. Disabled or failed sources are excluded; idle sources can still appear.

For two RTL-SDR dongles and one SDRplay receiver, an example is
`HEALTHCHECK_SDR_DEVICES=3` in `.env`, with `HEALTHCHECK_USB_0BDA_2838: "2"` and
`HEALTHCHECK_USB_1DF7_3000: "1"` under `owrx.environment` in `compose.yaml`.
Confirm your USB IDs with `lsusb`; they vary by device. Enable source counts only
once the expected receivers are configured and available.

Docker marks repeated failures as `unhealthy`. The `restart: unless-stopped`
policy applies when a container stops; it does not restart a running but unhealthy
container. The included [autoheal](https://github.com/willfarrell/docker-autoheal)
service watches the labeled OWRX container and restarts it when unhealthy.

## Updating the container

Back up your installation first. From the directory containing `compose.yaml`:

```sh
docker compose pull owrx
docker compose up -d --no-deps owrx
docker compose ps
```

This updates OWRX with the image selected in `.env`, briefly interrupting
reception. Settings and plugins remain in their mounted directories. Check
reception again using [Verify the installation](#verify-the-installation).

## Backup and restore

### What to preserve

Keep `compose.yaml`, `.env`, `etc`, `var` and `plugins` together in your backup.
These contain the deployment settings, admin setup values, receiver configuration,
application state and plugins. Include any extra bind mounts you add to the
Compose file. The archive does not contain Docker images or temporary files.

### Create a backup

For a consistent copy, stop autoheal and OWRX before archiving. The following
commands assume the quick-start layout at `/opt/owrx-docker` and briefly stop reception:

```sh
cd /opt/owrx-docker
docker compose stop autoheal owrx
sudo mkdir -p /opt/owrx-backups
backup="/opt/owrx-backups/owrx-$(date +%Y%m%d-%H%M%S).tar.gz"
sudo tar --numeric-owner -czpf "$backup" -C /opt \
  owrx-docker/compose.yaml owrx-docker/.env \
  owrx-docker/etc owrx-docker/var owrx-docker/plugins
docker compose up -d
sudo tar -tzf "$backup"
```

Confirm that the archive was created successfully and keep a copy on another
machine or storage device. If archiving fails, start the services again with
`docker compose up -d` before addressing the backup failure.

### Restore on a new host

Install Docker Engine and the Compose plugin, connect your SDR devices, and copy
the archive to the new host. Restore into `/opt` using an empty destination; if
an installation already exists there, stop its OWRX and autoheal services and
preserve its directories separately before restoring.

```sh
sudo mkdir -p /opt
sudo tar --numeric-owner -xzpf /path/to/owrx-backup.tar.gz -C /opt
cd /opt/owrx-docker
docker compose config --quiet
docker compose pull
docker compose up -d
```

Recheck USB device IDs, serial numbers, networking and timezone for the new host,
then [verify reception](#verify-the-installation). The `.env` image reference is
restored too, but `latest` may now refer to a newer build. Use an available fixed
image tag or digest in `OWRX_IMAGE` when you need to restore a specific build.

## Plugins

Add plugins under `/opt/owrx-docker/plugins/receiver` or
`/opt/owrx-docker/plugins/map`. See the
[plugin instructions](https://github.com/0xAF/openwebrxplus-plugins).

```sh
wget -O /opt/owrx-docker/plugins/receiver/init.js https://raw.githubusercontent.com/0xAF/openwebrxplus-plugins/main/receiver/init.js.sample
wget -O /opt/owrx-docker/plugins/map/init.js https://raw.githubusercontent.com/0xAF/openwebrxplus-plugins/main/map/init.js.sample
```

## Blacklisting Device Drivers (Host)

To avoid conflicts, blacklist the applicable SDR drivers on the host and reboot:

```sh
cat > /etc/modprobe.d/owrx-blacklist.conf << _EOF_
blacklist dvb_usb_rtl28xxu
blacklist sdr_msi3101
blacklist msi001
blacklist msi2500
blacklist hackrf
_EOF_
```

## Troubleshooting

### SDR disappears while the container stays healthy

Check the receiver list and recent health check output:

```sh
curl -fsS http://localhost:8073/status.json
docker inspect --format '{{json .State.Health}}' owrxp
docker compose logs --tail=100 owrx
```

Replace `owrxp` if you chose another container name. If the health output says
`HEALTHCHECK_SDR_DEVICES not set or <= 0`, the SDR count check is disabled.

For USB reconnection problems, compare device nodes on the host and inside the
container, and inspect the kernel journal on the host:

```sh
lsusb
lsusb -t
ls -l /dev/bus/usb
docker compose exec owrx ls -l /dev/bus/usb
sudo journalctl -k --since '1 hour ago'
```

Compare the numbered bus subdirectories as well. If the host has a new device node
that is absent inside the container, follow [USB passthrough and reconnection](#usb-passthrough-and-reconnection).
Repeated USB disconnects or descriptor errors need investigation on the host even
if restarting OWRX restores reception.

### SDRplay devices

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
