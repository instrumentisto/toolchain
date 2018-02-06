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

path="/usr/local/bin/"

# initVersion init current and latest stable version
initVersion(){

minikubeStableVersion=$( curl -s https://github.com/kubernetes/minikube/releases/ \
                        | grep -i "out/minikube-linux-amd64.sha256" -A 2 \
                        | awk '(NR == 2)' )

minikubeCurrentVersion=$( sha256sum /usr/local/bin/minikube \
                        | awk '{print $1}' )

kubectlCurrentVersion=$( kubectl version \
                        | sed -n '/.*v/s///p' \
                        | grep -o '^[^"]*' \
                        | head -n 1 )

kubectlLink=$( curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt )

helmStableRelease=$( curl -s https://github.com/kubernetes/helm/releases \
                        | grep -i 'rel="nofollow">Linux</a></li>' \
                        | sed -e 's/.*helm-v\(.*\)-.*/\1/' \
                        | cut -c1-5 | head -n 1 )

helmCurrentRelease=$( helm version | sed -n '/.*v/s///p' \
                        | grep -o '^[^"]*' \
                        | head -n 1 )
}

# minikubeLinuxInstall install minikube
minikubeLinuxInstall(){
  minikubeLink=$( curl -s https://github.com/kubernetes/minikube/releases \
              | grep -i "Linux/amd64" \
              | head -n 1 \
              | sed -e 's/.*a\ href="\(.*\)"\ .*/\1/' )

  curl -s -L $minikubeLink -o minikube
  runAsRoot chmod +x ./minikube
  runAsRoot mv ./minikube $path
}

# kubectlLinuxInstall kubectl install
kubectlLinuxInstall(){
  kubectlLink=$( curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt )
  curl -s -L https://storage.googleapis.com/kubernetes-release/release/"$kubectlLink"/bin/linux/amd64/kubectl -o kubectl
  runAsRoot chmod +x ./kubectl
  runAsRoot mv ./kubectl $path
}

# helmLinuxInstall helm install
helmLinuxInstall(){
  helmLink=$( curl -s https://github.com/kubernetes/helm/releases \
              | grep -i 'rel="nofollow">Linux</a>' \
              | head -n 1 \
              | sed -e 's/.*<a\ href="\(.*\)"\ rel="nofollow">Linux<.*/\1/' )

  curl -L -s $helmLink -o helm.tar.gz
  mkdir -p /tmp/helm
  tar -zxf helm.tar.gz -C /tmp/helm
  runAsRoot mv /tmp/helm/linux-amd64/helm $path
}

# checkIfInstall Check if minikube, kubectl and helm is installed
# if not - install those.
checkIfInstall(){

for pkg in minikube kubectl helm
  do
    if [[ -z $(which $pkg) ]]; then
      echo "$pkg not found"
        case $pkg in
          minikube)
            echo "Installing minikube..."
            minikubeLinuxInstall
          ;;
          kubectl)
            echo "Installing kubectl..."
            kubectlLinuxInstall
          ;;
          helm)
            echo "Installing helm..."
            helmLinuxInstall
          ;;
          *) exit 1
          ;;
        esac
    else
      echo "$pkg alreadey installed"
    fi
done
}

# upgradeLinuxSoft Check if the latest version of minikube, kubectl and helm is installed
# if not - upgrade to latest stable version
upgradeLinuxSoft(){

initVersion

if [[ "$minikubeCurrentVersion" == "$minikubeStableVersion" ]]; then
  echo "Minikube latest version"
else
  echo "Minikube need to upgrade"
  minikubeLinuxInstall
  echo "Minikube now is latest stable version."
fi

if [[ "v$kubectlCurrentVersion" == "$kubectlLink" ]]; then
  echo "Kubectl latest version"
else
  echo "Kubectl need to upgrade"
  kubectlLinuxInstall
  echo "Kubectl now is latest stable version."
fi

if [[ "$helmCurrentRelease" == "$helmStableRelease" ]]; then
  echo "Helm latest version"
else
  echo "Helm need to upgrade"
  helmLinuxInstall
  echo "Helm now is latest stable version."
fi
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
