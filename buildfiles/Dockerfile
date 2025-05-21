# Build the base image
FROM debian:bookworm-slim AS base
ARG MAKEFLAGS
ARG APT_PROXY
ADD files/sdrplay /sdrplay-patch
COPY install-base.sh common.sh /
#--mount=type=cache,target=/var/cache/apt \
RUN --mount=type=cache,target=/build_cache \
	/install-base.sh && rm -f /install-base.sh

FROM base AS sources
ARG MAKEFLAGS
ARG APT_PROXY
ARG BUILD_DATE
COPY install-sources.sh /
COPY --from=golang:bookworm /usr/local/go /usr/local/go
#--mount=type=cache,target=/var/cache/apt \
RUN --mount=type=cache,target=/build_cache \
    --mount=type=bind,source=files,target=/files \
	/install-sources.sh && rm -f /install-sources.sh

FROM base AS final
# FROM sources as final
ARG PRODUCT=openwebrxplus
#ARG VARIANT=nightly
ARG OWRXVERSION
ARG MAKEFLAGS
ARG BUILD_DATE
#ARG BUILD_SHA
COPY --from=sources /build-sources-date /build-sources-date
COPY install-owrx.sh /
COPY /files/run.sh /run.sh
#--mount=type=cache,target=/var/cache/apt \
RUN --mount=type=cache,target=/build_cache \
	/install-owrx.sh && rm -f /install-owrx.sh

COPY /files/healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh
HEALTHCHECK CMD /healthcheck.sh || exit 1

WORKDIR "/"
ENTRYPOINT ["/init"]
VOLUME /etc/openwebrx
VOLUME /var/lib/openwebrx

# ENV S6_CMD_ARG0="/run.sh"
# CMD [""]
# CMD ["/usr/bin/with-contenv","/bin/bash"]
# CMD ["/bin/bash"]

EXPOSE 8073


