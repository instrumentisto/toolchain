#!/bin/bash -x

# Define linux distribution (Debian or RHEL)
checkos() {

if [[ -f "/etc/debian_version" ]]; then
        echo "debian"
elif
   [[ -f "/etc/redhat-release" || "/etc/centos-release" ]]; then
        echo "redhat"
else
        echo "Error: cant check OS"
fi
}

init=$(checkos)

case $init in
        debian)
          release=$(echo `cat /etc/issue` | awk '{print $1, $2}' | tr '[:upper:]' '[:lower:]')
          echo $release
        ;;
          redhat|centos)
          echo "redhat/centos"
        ;;
        *)
          exit 1
        ;;
esac

# Check if minikube, helm and jubectl is installed.
checkInstalledSoft(){

tmp="/tmp"

for pkg in minikube helm kubectl; do
	if ! [[ -f $(which $pkg) ]]; then
		echo "Not found $pkg"
		echo "Installing package $pkg"
		  case $pkg in
		    minikube)
          curl -L https://storage.googleapis.com/minikube/releases/v0.25.0/minikube-linux-amd64 -o "$tmp/minikube"
          chmod +x $tmp/minikube
          mv $tmp/minikube /usr/local/bin/minikube
          ;;
        helm)
          curl -L https://storage.googleapis.com/kubernetes-helm/helm-v2.8.0-linux-amd64.tar.gz -o "$tmp/helm.tar.gz"
          tar -zxvf $tmp/helm.tar.gz -C $tmp
          mv $tmp/linux-amd64/helm /usr/local/bin/helm
          ;;
        kubectl)
          curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o "$tmp/kubectl"
          chmod +x $tmp/kubectl
          mv $tmp/kubectl /usr/local/bin/kubectl
          ;;
        *) exit 1
      esac
	fi

echo "All packages are installed"

done
}

# Check version of minikube, kubectl, helm and update if needed. Work example.
updatePackages(){

kubectlVer="1.9.1"
minikubeVer="0.24.1"
helmVer="2.8.0"

kubectlCurrentVer=$(kubectl version | sed -n '/.*v/s///p' | grep -o '^[^"]*' | head -n 1 )
minikubeCurrentVer=$(minikube version | sed -n '/.*v/s///p' | grep -o '^[^"]*' | head -n 1 )
helmCurrentVer=$(helm version | sed -n '/.*v/s///p' | grep -o '^[^"]*' | head -n 1 )

if ! (( $(awk 'BEGIN {print ("'$kubectlCurrentVer'" >= "'$kubectlVer'")}') )); then
    echo "Kubectl need to be upgrade"
    curl -LO https://storage.googleapis.com/kubernetes-release/release/\
    $(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mv ./kubectl /usr/local/bin/kubectl
elif
! (( $(awk 'BEGIN {print ("'$minikubeCurrentVer'" >= "'$minikubeVer'")}') )); then
   echo "Minikube need to be upgrade"
   curl -LO https://storage.googleapis.com/minikube/releases/v0.25.0/minikube-linux-amd64
   chmod +x ./minikube
   mv ./minikube /usr/local/bin/minikube
elif
! (( $(awk 'BEGIN {print ("'$helmCurrentVer'" >= "'$helmVer'")}') )); then
   echo "Helm need to be upgrade"
   curl -LO https://storage.googleapis.com/kubernetes-helm/helm-v2.8.0-linux-amd64.tar.gz
   tar -zxvf helm-v2.8.0-linux-amd64.tar.gz
   mv linux-amd64/helm /usr/local/bin/helm
fi
}

# Check version of minikube, kubectl, helm. Example. Not already done.
checkVerionTest() {
etalonVer=( [0]=0.24.1 [1]=2.7.2 [2]=1.9.1)

currentVer=( `for pkg in minikube helm kubectl; do $pkg version | sed -n '/.*v/s///p' | grep -o '^[^"]*' | head -n 1; done` )

for i in {0..2}; do

if ! (( $(awk 'BEGIN {print ("'${currentVer[$i]}'" >= "'${etalonVer[$i]}'")}') )); then
    echo "Old version"
fi

done
}


