#!/usr/bin/env bash

# Copyright 2018-2026  Instrumentisto Team
#
# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# initArch discovers the architecture for this system.
initArch() {
  ARCH=$(uname -m)
  case $ARCH in
    armv5*) ARCH="armv5";;
    armv6*) ARCH="armv6";;
    armv7*) ARCH="armv7";;
    aarch64) ARCH="arm64";;
    x86) ARCH="386";;
    x86_64) ARCH="amd64";;
    i686) ARCH="386";;
    i386) ARCH="386";;
  esac
}

# initOS discovers the operating system for this system.
initOS() {
  OS=$(echo `uname` | tr '[:upper:]' '[:lower:]')
  case "$OS" in
    # Minimalist GNU for Windows
    mingw*) OS='windows';;
  esac
}

# runAsRoot runs the given command as root (detects if we are root already).
runAsRoot() {
  local CMD="$*"
  if [ $EUID -ne 0 ]; then
    CMD="sudo $CMD"
  fi
  $CMD
}

# runIfNot runs the given command (all except 1st arg)
# if condition (1st arg) fails.
runIfNot() {
  (eval "$1" >/dev/null 2>&1) || runCmd ${@:2}
}

# runCmd prints the given command and runs it.
runCmd() {
  (set -x; $@)
}

# getGitHubLatestRelease gets the latest release from GitHub releases page.
# Example:
#   getGitHubLatestRelease "helm/helm"
getGitHubLatestRelease() {
  curl -sfL "https://api.github.com/repos/$1/releases/latest" \
    | grep -m1 '"tag_name":' \
    | cut -d '"' -f4
}

# upgradeHomebrewPackages upgrades required Homebrew packages to latest version.
upgradeHomebrewPackages() {
  runCmd \
    brew update
  for pkg in kubernetes-cli helm minikube; do
    if [ ! $(brew list -1 | grep $pkg) ]; then
      runCmd \
        brew install $pkg
    else
      runIfNot "brew outdated $pkg" \
        brew upgrade $pkg
    fi
  done
}

# upgradeChocoPackages upgrades required Chocolatey packages to latest version.
upgradeChocoPackages() {
  for pkg in kubernetes-cli kubernetes-helm minikube; do
    if [ ! "$(choco list --local-only | grep $pkg)" ]; then
      runCmd \
        choco install -y $pkg
    elif [ "$(choco outdated | grep $pkg)" ]; then
      runCmd \
        choco upgrade -y $pkg
    fi
  done
}

# upgradeRawBinaries upgrades required binaries to latest version.
upgradeRawBinaries() {
  if [ -z $(which helm) ]; then
    installHelmBinary
  else
    local HELM_LAST_VER=$(getGitHubLatestRelease "helm/helm")
    local HELM_CURR_VER=v$(helm version --client --short | cut -d '+' -f1 \
                                                         | cut -d 'v' -f2)
    if [ "$HELM_CURR_VER" != "$HELM_LAST_VER" ]; then
      installHelmBinary
    fi
  fi
  if [ -z $(which kubectl) ]; then
    installKubectlBinary
  else
    local KUBECTL_LAST_VER=$(curl -s \
           https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    local KUBECTL_CURR_VER=$(kubectl version --client --short | cut -f 3 -d " ")
    if [ "$KUBECTL_CURR_VER" != "$KUBECTL_LAST_VER" ]; then
      installKubectlBinary
    fi
  fi
  if [ -z $(which minikube) ]; then
    installMinikubeBinary
  else
    local MINIKUBE_LAST_VER=$(getGitHubLatestRelease "kubernetes/minikube")
    local MINIMUBE_CURR_VER=$(minikube version | cut -f 3 -d " ")
    if [ "$MINIMUBE_CURR_VER" != "$MINIKUBE_LAST_VER" ]; then
      installMinikubeBinary
    fi
  fi
}

# installHelmBinary upgrade binary helm package
installHelmBinary() {
  runAsRoot \
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    | bash
}

# installHelmBinary upgrade binary kubectl package
installKubectlBinary() {
  local VER=$(curl -s \
    https://storage.googleapis.com/kubernetes-release/release/stable.txt)
  runCmd \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/${VER}/bin/${OS}/${ARCH}/kubectl
  runAsRoot install kubectl /usr/local/bin/kubectl
  rm -f kubectl
}

# installHelmBinary upgrade binary minikube package
installMinikubeBinary() {
  runCmd \
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-${OS}-${ARCH}
  runAsRoot install minikube-${OS}-${ARCH} /usr/local/bin/minikube
  rm -f minikube-${OS}-${ARCH}
}

# installHyperkitDriver installs Hyperkit VM driver if it's not installed yet.
installHyperkitDriver() {
  if [ -z $(which docker-machine-driver-hyperkit) ]; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-hyperkit
    chmod +x docker-machine-driver-hyperkit
    runAsRoot mv docker-machine-driver-hyperkit /usr/local/bin/
    runAsRoot chown root:wheel /usr/local/bin/docker-machine-driver-hyperkit
    runAsRoot chmod u+s /usr/local/bin/docker-machine-driver-hyperkit
  fi
}


# Execution

set -e

initArch
initOS

MINIKUBE_K8S_VER=v${MINIKUBE_K8S_VER:-1.35.0}
MINIKUBE_BOOTSTRAPPER=${MINIKUBE_BOOTSTRAPPER:-kubeadm}
MINIKUBE_DISK_SIZE=${MINIKUBE_DISK_SIZE:-10g}
if [ -z "$MINIKUBE_VM_DRIVER" ]; then
  MINIKUBE_VM_DRIVER=virtualbox
  case "$OS" in
    darwin)
      MINIKUBE_VM_DRIVER=hyperkit
      ;;
  esac
fi

case "$OS" in
  darwin)
    upgradeHomebrewPackages
    if [ "$MINIKUBE_VM_DRIVER" == "hyperkit" ]; then
      installHyperkitDriver
    fi
    ;;
  windows)
    upgradeChocoPackages
    ;;
  linux)
    upgradeRawBinaries
    ;;
esac

if [[ ! -z "${MINIKUBE_NODE_IP}" ]]; then
  MINIKUBE_NODE_IP="--extra-config kubelet.node-ip=${MINIKUBE_NODE_IP}"
fi

runIfNot "minikube status | grep 'minikube:' | grep 'Running'" \
  minikube start --bootstrapper=$MINIKUBE_BOOTSTRAPPER \
                 --kubernetes-version=$MINIKUBE_K8S_VER \
                 --vm-driver=$MINIKUBE_VM_DRIVER \
                 ${MINIKUBE_NODE_IP} \
                 --disk-size=${MINIKUBE_DISK_SIZE}

runIfNot "minikube addons list | grep 'ingress' | grep 'enabled'" \
  minikube addons enable ingress

runCmd \
  minikube dashboard
