FROM coredns/coredns:1.14.6 AS coredns

FROM alpine:3.22

# iproute2 is required for Containerlab interface and route configuration.
# bind-tools supplies dig and other DNS troubleshooting utilities.
RUN apk add --no-cache iproute2 bind-tools

COPY --from=coredns /coredns /usr/local/bin/coredns

COPY Corefile /etc/coredns/Corefile
COPY db.requestflow.test /etc/coredns/db.requestflow.test

EXPOSE 53/udp
EXPOSE 53/tcp

ENTRYPOINT ["/usr/local/bin/coredns"]
CMD ["-conf", "/etc/coredns/Corefile"]
