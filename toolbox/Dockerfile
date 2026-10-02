FROM golang:1.27.1-trixie@sha256:3b77fc618ec235a1ab412de7737f120dd507c57e8d87de4cbb7994fb94275ed5 AS go-tools

# Verify module source through the Go checksum database and prevent automatic
# downloads of a different compiler by a dependency's toolchain directive.
ENV CGO_ENABLED=0 GOTOOLCHAIN=local

RUN go install -trimpath github.com/ffuf/ffuf/v2@v2.3.0 \
    && go install -trimpath github.com/OJ/gobuster/v3@v3.8.2 \
    && go install -trimpath github.com/projectdiscovery/httpx/cmd/httpx@v1.12.0 \
    && go install -trimpath github.com/projectdiscovery/nuclei/v3/cmd/nuclei@v3.11.1

# Nikto is not in Debian's main repository. Fetch a reviewed release at an
# immutable commit instead of enabling extra package repositories.
RUN git init /nikto \
    && git -C /nikto remote add origin https://github.com/sullo/nikto.git \
    && git -C /nikto fetch --depth=1 origin d201dac320fc5187eac75e723dd07a716196ec5a \
    && git -C /nikto checkout --detach FETCH_HEAD \
    && rm -rf /nikto/.git \
    && cp /nikto/program/nikto.conf.default /nikto/program/nikto.conf \
    && sed -i 's/^UPDATES=yes/UPDATES=no/' /nikto/program/nikto.conf

FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a

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
