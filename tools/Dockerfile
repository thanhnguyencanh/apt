# Toolchain image for generating a signed apt repository (static, GitHub-Pages ready).
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      apt-utils \
      dpkg-dev \
      gnupg \
      gzip \
 && rm -rf /var/lib/apt/lists/*

COPY generate.sh /usr/local/bin/generate.sh
RUN chmod +x /usr/local/bin/generate.sh
ENTRYPOINT ["/usr/local/bin/generate.sh"]
