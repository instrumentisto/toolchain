#!/usr/bin/env bash

# Copyright 2019 Instrumentisto Team
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

# genGitlabToken generates Gitlab personal access token with 'api' scope.
#
# Example:
#   genGitlabToken "https://gitlab.com" "user" "pass" "token-name"
genGitlabToken() {
  local GITLAB_URL="$1"
  local GITLAB_USER="$2"
  local GITLAB_PASS="$3"
  local GITLAB_TOKEN_NAME="$4"

  local COOKIES_FILE="$(mktemp --suffix=cookies)"

  # 1. Sign in into GitLab via username and password.
  local htmlContent=$(curl -c "$COOKIES_FILE" -i "$GITLAB_URL/users/sign_in" -s)
  local csrfToken=$(echo $htmlContent \
    | sed 's/.*<form class="new_user[^<]*\(<[^<]*\)\{2\}authenticity_token" value="\([^ ]*\)".*/\2/' \
    | sed -n 1p)
  curl -b "$COOKIES_FILE" -c "$COOKIES_FILE" -s --output /dev/null \
    -i "$GITLAB_URL/users/sign_in" \
    --data "user[login]=$GITLAB_USER&user[password]=$GITLAB_PASS" \
    --data-urlencode "authenticity_token=$csrfToken"
  if [[ "$(cat $COOKIES_FILE | grep _gitlab_session \
                            | awk '{print $5}')" != "0" ]]; then
    echo "Invalid username or password"
    exit 1
  fi

  # 2. Create personal access token for authorized user.
  local htmlContent=$(curl -s -H 'user-agent: curl' \
                           -b "$COOKIES_FILE" \
                           -i "$GITLAB_URL/profile/personal_access_tokens")
  local csrfToken=$(echo $htmlContent \
    | sed 's/.*authenticity_token" value="\([^ ]*\)".*/\1/' \
    | sed -n 1p)
  local htmlContent=$(curl -s -L \
    -b "$COOKIES_FILE" "$GITLAB_URL/profile/personal_access_tokens" \
    --data-urlencode "authenticity_token=$csrfToken" \
    --data "personal_access_token[name]=$GITLAB_TOKEN_NAME&personal_access_token[expires_at]=&personal_access_token[scopes][]=api")
  local gitlabToken=$(echo $htmlContent \
    | sed 's/.*created-personal-access-token" value="\([^ ]*\)".*/\1/' \
    | sed -n 1p)

  rm -f "$COOKIES_FILE"

  # 3. Verify that created personal access token is correct.
  verifyGitlabToken "$GITLAB_URL" "$GITLAB_USER" "$gitlabToken"
  if [[ "$?" -ne 0 ]]; then
    echo "Generated access token is incorrect"
    exit 1
  fi

  echo $gitlabToken
}

# verifyGitlabToken verifies that given GitLab personal access token
# belongs to specified GtiLab user.
#
# Example:
#   verifyGitlabToken "https://gitlab.com" "user" "token"
verifyGitlabToken() {
  local GITLAB_URL="$1"
  local GITLAB_USER="$2"
  local GITLAB_TOKEN="$3"

  local userField="username"
  if [[ "$GITLAB_USER" =~ .+@.+ ]]; then
    userField="email"
  fi

  local checkUser=$(curl -s -L \
                         "$GITLAB_URL/api/v4/user?private_token=$GITLAB_TOKEN" \
    | sed 's/.*"'$userField'":"\([^,]*\)".*/\1/')
  if [[ "$checkUser" != "$GITLAB_USER" ]]; then
    return 1
  fi
}


## Execution

gitlabUrl="${GITLAB_URL:-https://gitlab.com}"
k8sCluster="${K8S_CLUSTER:-staging}"

echo "Login to $GITLAB_URL"
read -p 'username: ' gitlabUser </dev/tty
read -s -p 'password: ' gitlabPass </dev/tty
echo -e "\nGitLab authentication..."

gitlabToken=$(genGitlabToken \
  "$gitlabUrl" "$gitlabUser" "$gitlabPass" "k8s-auth-$k8sCluster")
if [[ "$?" -ne 0 ]]; then
  echo "GitLab error: $gitlabToken"
  exit 1
fi
echo "GitLab Token: $gitlabToken"

k8sApi="${K8S_API:-https://127.0.0.1:443}"
k8sNamespaces="${K8S_NAMESPACES:-default}"

runCmd \
  kubectl config set-cluster $k8sCluster \
    --server=$k8sApi \
    --insecure-skip-tls-verify=true

runCmd \
  kubectl config set-credentials $gitlabUser \
    --token $gitlabToken

for namespace in $(echo $k8sNamespaces | tr "," "\n"); do
  runCmd \
    kubectl config set-context $namespace \
      --namespace=$namespace \
      --cluster=$k8sCluster \
      --user=$gitlabUser
done
