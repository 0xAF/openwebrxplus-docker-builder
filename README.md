# openwebrxplus-docker-builder
OpenWebRX+ docker images builder.  
Use this repo to build the official docker image and the SoftMBE image.  
The SoftMBE image uses codecserver-softmbe with mbelib-neo v2 by default, enabling DMR, D-Star, YSF, FreeDV, DRM, NXDN and other Digital modes.

## Install and run OpenWebRX+

**[Installation, Docker Compose, configuration and troubleshooting](docker.md)**

Start with the ready-to-use [compose.yaml](compose.yaml) and
[.env.example](.env.example). The [quick start](docker.md#quick-start) covers
installation, receiver setup and verification.

This GitHub repository is the primary home of the Docker image documentation.
Docker Compose is the supported installation and deployment method. The
installation guide covers both images:

| Image | Purpose |
| --- | --- |
| [`slechev/openwebrxplus`](https://hub.docker.com/r/slechev/openwebrxplus) | Standard image for general SDR reception and included demodulators |
| [`slechev/openwebrxplus-softmbe`](https://hub.docker.com/r/slechev/openwebrxplus-softmbe) | Standard image plus the SoftMBE decoder for modes such as DMR, D-Star and YSF |

Both images use the same Compose file, settings and persistent directories.
Choose the variant with `OWRX_IMAGE` in `.env`; see [choosing an image](docker.md#choosing-an-image).

## Support and contributions

See [Support](.github/SUPPORT.md) for help and issue reporting, and
[Contributing](.github/CONTRIBUTING.md) for local checks and pull requests.

## Building images

Set `USE_LEGACY_MBELIB=y` when invoking `./run` to build the SoftMBE image with the legacy mbelib and adapter branch. Any other non-empty value except `n` is rejected:

```sh
USE_LEGACY_MBELIB=y ./run build buildfiles/Dockerfile-softmbe
```

## Native Debian packages

The mbelib-neo packaging is maintained in this repository and can also be used
outside Docker:

```sh
git clone --branch v2.0.0 https://github.com/arancormonk/mbelib-neo.git
./buildfiles/prepare-mbelib-neo-debian.sh \
  ./mbelib-neo ./buildfiles/files/mbelib-neo-debian
(cd mbelib-neo && dpkg-buildpackage -b -us -uc)
```

This produces the `libmbe-neo2` runtime and `libmbe-neo-dev` development
packages. The matching adapter package is
`codecserver-driver-softmbe-neo`; use `apt install ./package.deb` for native
installation so package dependencies and the legacy-adapter conflict are
resolved automatically.
