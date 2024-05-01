# Build the base image
FROM debian:bookworm-slim as base
ARG MAKEFLAGS
ARG APT_PROXY
ADD files/sdrplay /tmp/sdrplay
COPY install-base.sh common.sh /tmp/
RUN --mount=type=cache,target=/build_cache --mount=type=cache,target=/var/cache/apt \
	/tmp/install-base.sh

FROM base as sources
ARG MAKEFLAGS
ARG APT_PROXY
ARG BUILD_DATE
COPY install-sources.sh /tmp
COPY --from=golang:bookworm /usr/local/go /usr/local/go
RUN --mount=type=cache,target=/build_cache --mount=type=cache,target=/var/cache/apt \
    --mount=type=bind,source=files,target=/files \
	/tmp/install-sources.sh

FROM base as final
# FROM sources as final
ARG PRODUCT=openwebrxplus
#ARG VARIANT=nightly
ARG OWRXVERSION
ARG MAKEFLAGS
ARG BUILD_DATE
#ARG BUILD_SHA
COPY --from=sources /build-sources-date /build-sources-date
COPY install-owrx.sh /tmp
COPY /files/run.sh /run.sh
RUN --mount=type=cache,target=/build_cache --mount=type=cache,target=/var/cache/apt \
	/tmp/install-owrx.sh

ENTRYPOINT ["/init"]
VOLUME /etc/openwebrx
VOLUME /var/lib/openwebrx

# ENV S6_CMD_ARG0="/run.sh"
# CMD [""]
# CMD ["/usr/bin/with-contenv","/bin/bash"]
# CMD ["/bin/bash"]

EXPOSE 8073


