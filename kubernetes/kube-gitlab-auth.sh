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


# runIfNot runs the given command (all except 1st arg)
# if condition (1st arg) fails.
runIfNot() {
  (eval "$1" >/dev/null 2>&1) || runCmd ${@:2}
}

# runCmd prints the given command and runs it.
runCmd() {
  (set -x; $@)
}

# getGitlabToken generate Gitlab personal access token with api scopes
# Example:
#   getGitlabToken "https://gitlab.com" "user" "pass"
getGitlabToken() {
  local GITLAB_URL=$1
  local GITLAB_USER=$2
  local GITLAB_PASS=$3
  local GITLAB_TOKEN_NAME="kubernetes"
  local COOKIES_FILE=$(mktemp --suffix=cookies)

  local htmlContent=$(curl -c "$COOKIES_FILE" -i "$GITLAB_URL/users/sign_in" -s)
  local csrfToken=$(echo $htmlContent \
    | sed 's/.*<form class="new_user[^<]*\(<[^<]*\)\{2\}authenticity_token" value="\([^ ]*\)".*/\2/' \
    | sed -n 1p)

  curl -b "$COOKIES_FILE" -c "$COOKIES_FILE" -s --output /dev/null \
    -i "$GITLAB_URL/users/sign_in" \
    --data "user[login]=$GITLAB_USER&user[password]=$GITLAB_PASS" \
    --data-urlencode "authenticity_token=$csrfToken"

  if [ "$(cat $COOKIES_FILE \
          | grep _gitlab_session \
          | awk '{print $5}')" == "0" ]; then
    local htmlContent=$(curl -H 'user-agent: curl' -b "$COOKIES_FILE" -i \
      "$GITLAB_URL/profile/personal_access_tokens" -s)
    local csrfToken=$(echo $htmlContent \
      | sed 's/.*authenticity_token" value="\([^ ]*\)".*/\1/' \
      | sed -n 1p)

    local htmlContent=$(curl -s -L \
      -b "$COOKIES_FILE" "$GITLAB_URL/profile/personal_access_tokens" \
      --data-urlencode "authenticity_token=$csrfToken" \
      --data "personal_access_token[name]=$GITLAB_TOKEN_NAME&personal_access_token[expires_at]=&personal_access_token[scopes][]=api")

    rm "$COOKIES_FILE"
    echo $htmlContent \
      | sed 's/.*created-personal-access-token" value="\([^ ]*\)".*/\1/' \
      | sed -n 1p
  else
    echo "Invalid username or password"
    exit 1
  fi
}


# Execution

gitlabUrl="${GITLAB_URL:-https://gitlab.com}"

echo "Login to $GITLAB_URL"
read -p 'username: ' gitlabUser </dev/tty
read -s -p 'password: ' gitlabPass </dev/tty
echo -e "\nGitLab authentication..."

gitlabToken=$(getGitlabToken "$gitlabUrl" "$gitlabUser" "$gitlabPass")
if [ "$?" -eq 0 ]; then
  echo "GitLab Token: $gitlabToken"

  ksClusterName="${KUBE_CLUSTER_NAME:-workspace}"
  ksClusterApi="${KUBE_CLUSTER_API:-https://127.0.0.1:443}"
  ksClusterNamespaces="${KUBE_NAMESPACES:-default}"

  runCmd \
    kubectl config set-cluster $ksClusterName \
      --server=$ksClusterApi \
      --insecure-skip-tls-verify=true

  runCmd \
    kubectl config set-credentials gitlab.$gitlabUser \
      --token $gitlabToken

  for namespace in $(echo $ksClusterNamespaces | tr "," "\n")
  do
    runCmd \
      kubectl config set-context $namespace \
        --namespace=$namespace \
        --cluster=$ksClusterName \
        --user=gitlab.$gitlabUser
  done

else
  echo "GitLab error: $gitlabToken"
fi
