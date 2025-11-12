ARG python_ver=3.13.7
# https://hub.docker.com/_/python/
FROM python:${python_ver}-slim-trixie

ARG image_ver=1.4.2
ARG ansible_ver=9.13.0
ARG biome_ver=2.3.5
ARG butane_ver=0.25.1
ARG deno_ver=2.5.6
ARG doctl_ver=1.147.0
ARG hcloud_ver=1.57.0
ARG helm_ver=3.19.1
ARG jsonnet_ver=0.21.0
ARG jsonnet_bundler_ver=0.6.0
ARG kubectl_ver=1.34.2
ARG terraform_ver=1.13.5

# Indication that the current context is inside this toolchain container.
ENV TOOLCHAIN=1

# Prepare project directory.
RUN mkdir -p /app/
WORKDIR /app/

# Install basic tools and update certificates.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            ca-certificates \
            curl \
            git \
            libvirt-clients \
            make \
            rsync \
            ssh \
            tini \
            zip unzip \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Install Ansible and its dependencies.
ENV PIPX_BIN_DIR=/usr/local/bin/
COPY ansible/ansible-galaxy.deps.yml \
     ansible/pip.requirements.txt \
     /deps/
RUN pip install pipx \
    \
 && pipx install --include-deps ansible==${ansible_ver} \
    \
 && cat /deps/pip.requirements.txt \
    | xargs pipx inject ansible \
 && ansible-galaxy install -r /deps/ansible-galaxy.deps.yml \
    \
 && pip cache purge \
 && rm -rf /var/lib/apt/lists/* \
           /root/.local/share/man/ \
           /root/.local/state/

# Install Biome.
RUN curl -fL -o /usr/local/bin/biome \
         https://github.com/biomejs/biome/releases/download/%40biomejs%2Fbiome%40${biome_ver}/biome-linux-x64 \
 && chmod +x /usr/local/bin/biome \
    \
 && mkdir -p /usr/local/share/doc/biome/ \
 && curl -fL -o /usr/local/share/doc/biome/LICENSE-APACHE \
         https://raw.githubusercontent.com/biomejs/biome/%40biomejs%2Fbiome%40${biome_ver}/LICENSE-APACHE \
 && curl -fL -o /usr/local/share/doc/biome/LICENSE-MIT \
         https://raw.githubusercontent.com/biomejs/biome/%40biomejs%2Fbiome%40${biome_ver}/LICENSE-MIT

# Install Butane.
RUN curl -fL -o /usr/local/bin/butane \
         https://github.com/coreos/butane/releases/download/v${butane_ver}/butane-x86_64-unknown-linux-gnu \
 && chmod +x /usr/local/bin/butane \
    \
 && mkdir -p /usr/local/share/doc/butane/ \
 && curl -fL -o /usr/local/share/doc/butane/LICENSE \
         https://raw.githubusercontent.com/coreos/butane/v${butane_ver}/LICENSE

# Install Deno.
RUN curl -fsSL https://deno.land/install.sh \
    | DENO_INSTALL=/usr/local deno_version=v${deno_ver} sh

# Install DigitalOcean CLI.
RUN curl -fsL https://github.com/digitalocean/doctl/releases/download/v${doctl_ver}/doctl-${doctl_ver}-linux-amd64.tar.gz \
    | tar -xz -C /usr/local/bin/ \
          doctl \
    \
 && mkdir -p /usr/local/share/doc/doctl/ \
 && curl -fL -o /usr/local/share/doc/doctl/LICENSE.txt \
         https://raw.githubusercontent.com/digitalocean/doctl/v${doctl_ver}/LICENSE.txt

# Install Hetzner Cloud CLI.
RUN curl -fL -o /tmp/hcloud.tar.gz \
         https://github.com/hetznercloud/cli/releases/download/v${hcloud_ver}/hcloud-linux-amd64.tar.gz \
 && tar -xzf /tmp/hcloud.tar.gz -C /usr/local/bin/ \
        hcloud \
    \
 && mkdir -p /usr/local/share/doc/hcloud/ \
 && tar -xzf /tmp/hcloud.tar.gz -C /usr/local/share/doc/hcloud/ LICENSE \
    \
 && rm -rf /tmp/*

# Install Helm.
RUN curl -fL -o /tmp/helm.tar.gz \
         https://get.helm.sh/helm-v${helm_ver}-linux-amd64.tar.gz \
 && tar -xzf /tmp/helm.tar.gz -C /usr/local/bin/ \
                              --strip-components=1 \
        linux-amd64/helm \
    \
 && mkdir -p /usr/local/share/doc/helm/ \
 && tar -xzf /tmp/helm.tar.gz -C /usr/local/share/doc/helm/ \
                              --strip-components=1 \
        linux-amd64/LICENSE \
    \
 && rm -rf /tmp/*

# Install Jsonnet.
RUN curl -fL -o /tmp/jsonnet.tar.gz \
         https://github.com/google/go-jsonnet/releases/download/v${jsonnet_ver}/go-jsonnet_Linux_x86_64.tar.gz \
 && tar -xzf /tmp/jsonnet.tar.gz -C /usr/local/bin/ \
        jsonnet jsonnet-deps jsonnet-lint jsonnetfmt \
    \
 && mkdir -p /usr/local/share/doc/jsonnet/ \
 && tar -xzf /tmp/jsonnet.tar.gz -C /usr/local/share/doc/jsonnet/ \
        LICENSE \
    \
 && rm -rf /tmp/*

# Install Jsonnet Bundler.
RUN curl -fL -o /usr/local/bin/jb \
    https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/v${jsonnet_bundler_ver}/jb-linux-amd64 \
 && chmod +x /usr/local/bin/jb \
    \
 && mkdir -p /usr/local/share/doc/jb/ \
 && curl -fL -o /usr/local/share/doc/jb/LICENSE \
         https://raw.githubusercontent.com/jsonnet-bundler/jsonnet-bundler/v${jsonnet_bundler_ver}/LICENSE

# Install Kubernetes CLI.
RUN curl -fL -o /usr/local/bin/kubectl \
         https://dl.k8s.io/release/v${kubectl_ver}/bin/linux/amd64/kubectl \
 && chmod +x /usr/local/bin/kubectl \
    \
 && mkdir -p /usr/local/share/doc/kubectl/ \
 && curl -fL -o /usr/local/share/doc/kubectl/LICENSE \
         https://raw.githubusercontent.com/kubernetes/kubernetes/v${kubectl_ver}/LICENSES/LICENSE

# Install Terraform.
RUN apt-get update \
 && toolDeps="libarchive-tools" \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            $toolDeps \
    \
 && curl -fL -o /tmp/terraform.zip \
         https://releases.hashicorp.com/terraform/${terraform_ver}/terraform_${terraform_ver}_linux_amd64.zip \
 && bsdtar -C /usr/local/bin/ -xf /tmp/terraform.zip \
           terraform \
 && chmod +x /usr/local/bin/terraform \
    \
 && mkdir -p /usr/local/share/doc/terraform/ \
 && bsdtar -C /usr/local/share/doc/terraform/ -xf /tmp/terraform.zip \
           LICENSE.txt \
    \
 && apt-get purge -y --auto-remove \
                      -o APT::AutoRemove::RecommendsImportant=false \
            $toolDeps \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

ENTRYPOINT ["/usr/bin/tini", "--"]
