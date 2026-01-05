#!/usr/bin/env bash

# Copyright 2019-2026  Instrumentisto Team
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


# runCmd prints the given command and runs it.
runCmd() {
  (set -x; $@)
}


# Execution

set -e

if [[ -z "$RUSTUP_NIGHTLY_DATE" ]]; then
  echo 'Error: RUSTUP_NIGHTLY_DATE must be specified'
  exit 1
fi

if [[ "$RUSTUP_FORCE" == 'yes' ]]; then
  RUSTUP_FORCE='--force'
else
  RUSTUP_FORCE=''
fi

RUSTUP_DEFAULT_HOST_TRIPLE=$(rustup show \
                             | grep 'Default host: ' \
                             | cut -d':' -f2 \
                             | tr -d ' \n')

runCmd rustup install nightly-$RUSTUP_NIGHTLY_DATE $RUSTUP_FORCE
if [[ -z "$RUSTUP_FORCE" ]]; then
  runCmd rustup component add rustfmt --toolchain nightly-$RUSTUP_NIGHTLY_DATE
  runCmd rustup component add clippy --toolchain nightly-$RUSTUP_NIGHTLY_DATE
fi
runCmd ln -snf ~/.rustup/toolchains/nightly-$RUSTUP_NIGHTLY_DATE-$RUSTUP_DEFAULT_HOST_TRIPLE \
       ~/.rustup/toolchains/nightly-$RUSTUP_DEFAULT_HOST_TRIPLE
runCmd ln -snf ~/.rustup/update-hashes/nightly-$RUSTUP_NIGHTLY_DATE-$RUSTUP_DEFAULT_HOST_TRIPLE \
       ~/.rustup/update-hashes/nightly-$RUSTUP_DEFAULT_HOST_TRIPLE
