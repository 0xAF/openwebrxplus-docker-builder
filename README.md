# openwebrxplus-docker-builder
OpenWebRX+ docker images builder.  
Use this repo to build the official docker image and the SoftMBE image.  
The SoftMBE image uses codecserver-softmbe with mbelib-neo v2 by default, enabling DMR, D-Star, YSF, FreeDV, DRM, NXDN and other Digital modes.

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

# Docker Hub
Check the [Docker Hub](https://hub.docker.com/r/slechev/openwebrxplus) page for the official image.  
Check the [Docker Hub](https://hub.docker.com/r/slechev/openwebrxplus-softmbe) page for the softmbe image.

# Install
See the [info of the official image](https://hub.docker.com/r/slechev/openwebrxplus).
