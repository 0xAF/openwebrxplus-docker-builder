FROM debian:bookworm-slim AS build
ARG MAKEFLAGS
COPY build-packages.sh /tmp/
RUN /tmp/build-packages.sh

FROM slechev/openwebrxplus:latest
ARG ARCH
ARG MAKEFLAGS
COPY --from=build /deb /deb
COPY install-packages.sh /tmp/
RUN /tmp/install-packages.sh

#ENV S6_CMD_ARG0="/opt/openwebrx/docker/scripts/run.sh"
#WORKDIR /opt/openwebrx

ENTRYPOINT ["/init"]
VOLUME /etc/openwebrx
VOLUME /var/lib/openwebrx

# CMD []

EXPOSE 8073
