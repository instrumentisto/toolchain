#!/usr/bin/env bash

# Copyright 2018 Instrumentisto Team
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

# upgradeHomebrewPackages upgrades required Homebrew packages to latest version.
upgradeHomebrewPackages() {
  runCmd \
    brew update
  runIfNot "brew tap | grep 'caskroom/cask'" \
    brew tap caskroom/cask
  runIfNot "brew cask outdated minikube | test -z" \
    brew cask reinstall minikube
  for pkg in kubernetes-cli kubernetes-helm; do
    if [ ! $(brew list | grep $pkg) ]; then
      runCmd \
        brew install $pkg
    else
      runIfNot "brew outdated $pkg" \
        brew upgrade $pkg --cleanup
    fi
  done
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

# checkDashboardIsDeployed checks if Kubernetes Dashboard is deployed
# into Minikube.
checkDashboardIsDeployed() {
  kubectl --context=minikube --namespace=kube-system get pods \
    | grep kubernetes-dashboard | grep Running >/dev/null 2>&1
}

# waitDashboardIsDeployed waits until Kubernetes Dashboard is deployed
# into Minikube.
waitDashboardIsDeployed() {
  set +e
  checkDashboardIsDeployed
  while [ $? -ne 0 ]; do
    sleep 1
    checkDashboardIsDeployed
  done
  set -e
}

helmLinuxUpgradeTest() {
  LATEST_VER=`curl -s https://github.com/kubernetes/helm/releases/latest | sed -e 's/.*v\(.*\)".*/\1/'`
  CURRENT_VER=`helm version 2>/dev/null | sed -n '/.*v/s///p' | grep -o '^[^"]*' | head -n 1`
  if ! [[ "$CURRENT_VER" == "$LATEST_VER" ]]; then
    curl -s -LO https://storage.googleapis.com/kubernetes-helm/helm-v$LATEST_VER-linux-$ARCH.tar.gz
    tar -zxf helm-v$LATEST_VER-linux-$ARCH.tar.gz
    mv linux-$ARCH/helm /usr/local/bin
  fi
}

minikubeLinuxInstall() {
  unset LATEST_VER CURRENT_VER SHA CHECK_VER
  LATEST_VER=`curl -s https://github.com/kubernetes/minikube/releases/latest| sed -e 's/.*v\(.*\)".*/\1/'`
  curl -s -L https://github.com/kubernetes/minikube/releases/download/v$LATEST_VER/minikube-linux-$ARCH -o \
    /tmp/minikube
  chmod +x /tmp/minikube
  mv /tmp/minikube /usr/local/bin
}

minikubeLinuxUpgrade() {
  unset LATEST_VER CURRENT_VER SHA CHECK_VER
  LATEST_VER=`curl -s https://github.com/kubernetes/minikube/releases/latest| sed -e 's/.*v\(.*\)".*/\1/'`
  SHA=`curl -s -L https://github.com/kubernetes/minikube/releases/download/v$LATEST_VER/minikube-linux-$ARCH.sha256 -o \
    /tmp/minikube.sha256`
  CHECK_VER=$(echo `cat /tmp/minikube.sha256` /usr/local/bin/minikube | sha256sum -c)
  if [[ "$?" -eq "1" ]]; then
    minikubeLinuxInstall
  fi
}

helmLinuxInstall() {
  unset LATEST_VER CURRENT_VER SHA CHECK_VER
  LATEST_VER=`curl -s https://github.com/kubernetes/helm/releases/latest | sed -e 's/.*v\(.*\)".*/\1/'`
  curl -s -LO https://storage.googleapis.com/kubernetes-helm/helm-v$LATEST_VER-linux-$ARCH.tar.gz
  tar -zxf helm-v$LATEST_VER-linux-$ARCH.tar.gz
  mv linux-$ARCH/helm /usr/local/bin
}

helmLinuxUpgrade() {
  unset LATEST_VER CURRENT_VER SHA CHECK_VER
  LATEST_VER=`curl -s https://github.com/kubernetes/helm/releases/latest | sed -e 's/.*v\(.*\)".*/\1/'`
  CURRENT_VER=`helm version 2>/dev/null | sed -n '/.*v/s///p' | grep -o '^[^"]*' | head -n 1`
  if ! [[ "$CURRENT_VER" == "$LATEST_VER" ]]; then
    helmLinuxInstall
  fi
}

kubectlLinuxInstall() {
  unset LATEST_VER CURRENT_VER SHA CHECK_VER
  LATEST_VER=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`
  curl -s -L https://storage.googleapis.com/kubernetes-release/release/$LATEST_VER/bin/linux/$ARCH/kubectl -o \
   /tmp/kubectl
  chmod +x /tmp/kubectl
  mv /tmp/kubectl /usr/local/bin/
}

kubectlLinuxUpgrade() {
  unset LATEST_VER CURRENT_VER SHA CHECK_VER
  LATEST_VER=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`
  SHA=`curl -s -L https://storage.googleapis.com/kubernetes-release/release/$LATEST_VER/bin/linux/$ARCH/kubectl.sha1 -o\
    /tmp/kubectl.sha1`
  CHECK_VER=$(echo `cat /tmp/kubectl.sha1` /usr/local/bin/kubectl | sha1sum -c 2>/dev/null)
  if [[ "$?" -eq "1" ]];then
    kubectlLinuxInstall
  fi
}

upgradeLinuxPackages() {
  for PKG in minikube helm kubectl; do
    INSTALL_PATH=`which $PKG`
      if [[ -z "$INSTALL_PATH" ]]; then
        case $PKG in
          minikube) minikubeLinuxInstall ;;
          helm) helmLinuxInstall ;;
          kubectl)kubectlLinuxInstall ;;
          *) exit 1 ;;
        esac
      else
        case $INSTALL_PATH in
          /usr/local/bin/minikube) minikubeLinuxUpgrade ;;
          /usr/local/bin/helm) helmLinuxUpgradeTest ;;
          /usr/local/bin/kubectl) kubectlLinuxUpgrade ;;
          *) exit 1 ;;
        esac
      fi
  done
}


# Execution

set -e

initArch
initOS

MINIKUBE_K8S_VER=v1.9.2
MINIKUBE_BOOTSTRAPPER=kubeadm
MINIKUBE_VM_DRIVER=virtualbox
case "$OS" in
  darwin)
    # TODO: Hyperkit driver is still not stable enough. Use with later releases.
    #MINIKUBE_VM_DRIVER=hyperkit
    ;;
esac

case "$OS" in
  darwin)
    upgradeHomebrewPackages
    # TODO: Hyperkit driver is still not stable enough. Use with later releases.
    #installHyperkitDriver
    ;;
  linux)
    checkIfInstall
    upgradeLinuxSoft
    ;;
esac

runIfNot "minikube status | grep 'minikube:' | grep 'Running'" \
  minikube start --bootstrapper=$MINIKUBE_BOOTSTRAPPER \
                 --kubernetes-version=$MINIKUBE_K8S_VER \
                 --vm-driver=$MINIKUBE_VM_DRIVER \
                 --disk-size=10g

runIfNot "minikube addons list | grep 'ingress' | grep 'enabled'" \
  minikube addons enable ingress

runCmd \
  helm init --kube-context=minikube

waitDashboardIsDeployed
runCmd \
  minikube dashboard

eval $(minikube docker-env)
