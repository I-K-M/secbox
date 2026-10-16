FROM golang:1.27.1-trixie@sha256:8f58fd67ea075142d947a60e0caa4317746a55118d312f027793d382c7741734 AS go-tools

# Verify module source through the Go checksum database and prevent automatic
# downloads of a different compiler by a dependency's toolchain directive.
ENV CGO_ENABLED=0 GOTOOLCHAIN=local

# A shared, committed module graph upgrades vulnerable upstream transitive
# dependencies. -mod=readonly prevents builds from changing that graph.
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download \
    && go install -mod=readonly -trimpath github.com/ffuf/ffuf/v2 \
    && go install -mod=readonly -trimpath github.com/OJ/gobuster/v3 \
    && go install -mod=readonly -trimpath github.com/projectdiscovery/httpx/cmd/httpx \
    && go install -mod=readonly -trimpath github.com/projectdiscovery/nuclei/v3/cmd/nuclei

# Nikto is not in Debian's main repository. Fetch a reviewed release at an
# immutable commit instead of enabling extra package repositories.
RUN git init /nikto \
    && git -C /nikto remote add origin https://github.com/sullo/nikto.git \
    && git -C /nikto fetch --depth=1 origin d201dac320fc5187eac75e723dd07a716196ec5a \
    && git -C /nikto checkout --detach FETCH_HEAD \
    && rm -rf /nikto/.git \
    && cp /nikto/program/nikto.conf.default /nikto/program/nikto.conf \
    && sed -i 's/^UPDATES=yes/UPDATES=no/' /nikto/program/nikto.conf

FROM debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f

LABEL org.opencontainers.image.title="Secbox" \
      org.opencontainers.image.description="Disposable security assessment toolbox" \
      org.opencontainers.image.source="https://github.com/I-K-M/secbox" \
      org.opencontainers.image.url="https://github.com/I-K-M/secbox"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash ca-certificates curl wget git jq ripgrep file less vim-tiny tmux \
        python3 python3-pip python3-venv pipx \
        nmap netcat-openbsd socat dnsutils whois iputils-ping iproute2 \
        tcpdump tshark masscan traceroute openvpn \
        sqlmap whatweb hydra john hashcat \
        yara exiftool binwalk openssl perl libnet-ssleay-perl liburi-perl libxml-writer-perl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=go-tools /go/bin/ /usr/local/bin/
COPY --from=go-tools /nikto/program/ /opt/nikto/
COPY nikto.sh /usr/local/bin/nikto
COPY tools-check.sh /usr/local/bin/secbox-check

RUN useradd --create-home --uid 1000 --shell /bin/bash secbox \
    && mkdir -p /work /labs /scripts /wordlists \
    && chown secbox:secbox /work \
    && chmod 0755 /usr/local/bin/secbox-check /usr/local/bin/nikto \
    && find / -xdev -type f -perm /6000 -exec chmod a-s {} +

USER 1000:1000
ENV HOME=/home/secbox \
    PATH=/home/secbox/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin \
    PIPX_HOME=/home/secbox/.local/pipx \
    PIPX_BIN_DIR=/home/secbox/.local/bin

WORKDIR /work

CMD ["/bin/bash"]
