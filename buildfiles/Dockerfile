# Build the base image
FROM debian:bookworm-slim AS base
ARG MAKEFLAGS
ARG APT_PROXY
ADD files/sdrplay /sdrplay-patch
COPY common.sh /
COPY scripts/base /scripts/base
#--mount=type=cache,target=/var/cache/apt \
RUN --mount=type=cache,id=owrxp-buildcache-bookworm,target=/build_cache \
	bash -c 'source /common.sh && run_numbered_scripts /scripts/base'

FROM base AS sources
ARG MAKEFLAGS
ARG APT_PROXY
ARG SOURCES_SCRIPTS_FINGERPRINT
COPY scripts/sources /scripts/sources
COPY --from=golang:bookworm /usr/local/go /usr/local/go
#--mount=type=cache,target=/var/cache/apt \
RUN --mount=type=cache,id=owrxp-buildcache-bookworm,target=/build_cache \
    --mount=type=bind,source=files,target=/files \
	bash -c 'echo "${SOURCES_SCRIPTS_FINGERPRINT}" > /build-sources-scripts-fingerprint && source /common.sh && run_numbered_scripts /scripts/sources'

FROM base AS final
ARG PRODUCT=openwebrxplus
#ARG VARIANT=nightly
ARG OWRXVERSION
ARG MAKEFLAGS
ARG BUILD_DATE
ARG OWRX_REPO_COMMIT
ARG FINAL_CACHE_BUSTER
#ARG BUILD_SHA
COPY scripts/final /scripts/final
COPY /files/run.sh /run.sh
# Copy build artifacts from sources stage via layer (not cache mount, which can desync).
COPY --from=sources /build-sources-scripts-fingerprint /build-sources-scripts-fingerprint
COPY --from=sources /build_artifacts /build_artifacts
#--mount=type=cache,target=/var/cache/apt \
RUN bash -c 'mkdir -p /build_cache && source /common.sh && run_numbered_scripts /scripts/final'

COPY /files/healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

#FROM scratch AS export
#COPY --from=final / /

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


