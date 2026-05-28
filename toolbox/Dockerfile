FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends \
    bash \
    curl \
    wget \
    git \
    vim \
    nano \
    tmux \
    jq \
    ripgrep \
    unzip \
    zip \
    file \
    less \
    python3 \
    python3-pip \
    python3-venv \
    openssl \
    netcat-openbsd \
    dnsutils \
    iputils-ping \
    iproute2 \
    whois \
    nmap \
    tcpdump \
    tshark \
    sqlmap \
    hydra \
    john \
    yara \
    golang \
    && apt clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash secboxr

USER secboxr

ENV HOME=/home/secboxr
ENV PATH=$HOME/go/bin:$PATH

WORKDIR /work

RUN go install github.com/ffuf/ffuf/v2@latest

CMD ["/bin/bash"]