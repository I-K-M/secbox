FROM golang:1.24-bookworm AS go-tools

ENV CGO_ENABLED=0

RUN go install github.com/ffuf/ffuf/v2@v2.1.0 \
    && go install github.com/OJ/gobuster/v3@v3.6.0 \
    && go install github.com/projectdiscovery/httpx/cmd/httpx@v1.6.10 \
    && go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@v3.3.10

FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash ca-certificates curl wget git jq ripgrep file less vim-tiny tmux \
        python3 python3-pip python3-venv pipx \
        nmap netcat-openbsd socat dnsutils whois iputils-ping iproute2 \
        tcpdump tshark masscan traceroute openvpn \
        sqlmap nikto whatweb hydra john hashcat \
        yara exiftool binwalk openssl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=go-tools /go/bin/ffuf /usr/local/bin/ffuf
COPY --from=go-tools /go/bin/gobuster /usr/local/bin/gobuster
COPY --from=go-tools /go/bin/httpx /usr/local/bin/httpx
COPY --from=go-tools /go/bin/nuclei /usr/local/bin/nuclei
COPY tools-check.sh /usr/local/bin/secbox-check

RUN useradd --create-home --uid 1000 --shell /bin/bash secbox \
    && chmod 0755 /usr/local/bin/secbox-check

USER 1000:1000
ENV HOME=/home/secbox \
    PATH=/home/secbox/.local/bin:/usr/local/bin:/usr/bin:/bin \
    PIPX_HOME=/home/secbox/.local/pipx \
    PIPX_BIN_DIR=/home/secbox/.local/bin

WORKDIR /work

CMD ["/bin/bash"]
