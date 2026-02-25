#!/usr/bin/env bats


@test "ansible runs ok" {
  run docker run --rm --pull never $IMAGE \
    ansible --help
  [ "$status" -eq 0 ]
}

@test "ansible has correct version" {
  run sh -c "grep 'ARG ansible_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "ansible-community --version | cut -d ' ' -f4"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "bash runs ok" {
  run docker run --rm --pull never $IMAGE bash -c \
    'printf hi'
  [ "$status" -eq 0 ]
  [ "$output" == "hi" ]
}


@test "biome runs ok" {
  run docker run --rm --pull never $IMAGE \
    biome --help
  [ "$status" -eq 0 ]
}

@test "biome has correct version" {
  run sh -c "grep 'ARG biome_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "biome version | grep 'CLI:' | cut -d ':' -f2 | tr -d ' '"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "butane runs ok" {
  run docker run --rm --pull never $IMAGE \
    butane --help
  [ "$status" -eq 0 ]
}

@test "butane has correct version" {
  run sh -c "grep 'ARG butane_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "butane --version | cut -d ' ' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "curl runs ok" {
  run docker run --rm --pull never $IMAGE \
    curl --help
  [ "$status" -eq 0 ]
}


@test "deno runs ok" {
  run docker run --rm --pull never $IMAGE \
    deno --help
  [ "$status" -eq 0 ]
}

@test "deno has correct version" {
  run sh -c "grep 'ARG deno_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "deno --version | grep 'deno ' | cut -d ' ' -f2 | cut -d '+' -f1"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "doctl runs ok" {
  run docker run --rm --pull never $IMAGE \
    doctl --help
  [ "$status" -eq 0 ]
}

@test "doctl has correct version" {
  run sh -c "grep 'ARG doctl_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "doctl version | grep 'doctl ' | cut -d ' ' -f3 | cut -d '-' -f1"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "git runs ok" {
  run docker run --rm --pull never $IMAGE \
    git --help
  [ "$status" -eq 0 ]
}


@test "hcloud runs ok" {
  run docker run --rm --pull never $IMAGE \
    hcloud --help
  [ "$status" -eq 0 ]
}

@test "hcloud has correct version" {
  run sh -c "grep 'ARG hcloud_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "hcloud version | cut -d ' ' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "helm runs ok" {
  run docker run --rm --pull never $IMAGE \
    helm --help
  [ "$status" -eq 0 ]
}

@test "helm has correct version" {
  run sh -c "grep 'ARG helm_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "helm version | grep 'Version:' | cut -d ':' -f2 | cut -d '\"' -f2 \
                                                     | cut -d 'v' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "jsonnet runs ok" {
  run docker run --rm --pull never $IMAGE \
    jsonnet --help
  [ "$status" -eq 0 ]
}

@test "jsonnet has correct version" {
  run sh -c "grep 'ARG jsonnet_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "jsonnet --version | cut -d 'v' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}

@test "jb (jsonnet bundler) runs ok" {
  run docker run --rm --pull never $IMAGE \
    jb --help
  [ "$status" -eq 0 ]
}

@test "jb (jsonnet bundler) has correct version" {
  run sh -c "grep 'ARG jsonnet_bundler_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "jb --version 2>&1 | cut -d 'v' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "kubectl runs ok" {
  run docker run --rm --pull never $IMAGE \
    kubectl --help
  [ "$status" -eq 0 ]
}

@test "kubectl has correct version" {
  run sh -c "grep 'ARG kubectl_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "kubectl version --client=true | grep 'Client Version:' | cut -d 'v' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "make runs ok" {
  run docker run --rm --pull never $IMAGE \
    make --help
  [ "$status" -eq 0 ]
}


@test "python runs ok" {
  run docker run --rm --pull never $IMAGE \
    python --help
  [ "$status" -eq 0 ]
}

@test "python has correct version" {
  run sh -c "grep 'ARG python_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "python --version | cut -d ' ' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "rsync runs ok" {
  run docker run --rm --pull never $IMAGE \
    rsync --help
  [ "$status" -eq 0 ]
}


@test "ssh runs ok" {
  run docker run --rm --pull never $IMAGE \
    ssh -V
  [ "$status" -eq 0 ]
}


@test "terraform runs ok" {
  run docker run --rm --pull never $IMAGE \
    terraform --help
  [ "$status" -eq 0 ]
}

@test "terraform has correct version" {
  run sh -c "grep 'ARG terraform_ver=' Dockerfile | cut -d '=' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run docker run --rm --pull never $IMAGE sh -c \
    "terraform --version | grep 'Terraform v' | cut -d 'v' -f2"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "vim runs ok" {
  run docker run --rm --pull never $IMAGE \
    vim --help
  [ "$status" -eq 0 ]
}


@test "virsh runs ok" {
  run docker run --rm --pull never $IMAGE \
    virsh --help
  [ "$status" -eq 0 ]
}


@test "zip runs ok" {
  run docker run --rm --pull never $IMAGE \
    zip --help
  [ "$status" -eq 0 ]
}

@test "unzip runs ok" {
  run docker run --rm --pull never $IMAGE \
    unzip --help
  [ "$status" -eq 0 ]
}


@test "Working directory is set to /app" {
  run docker run --rm --pull never $IMAGE \
    pwd
  [ "$status" -eq 0 ]
  [ "$output" = "/app" ]
}


@test "TOOLCHAIN environment variable is set" {
  run docker run --rm --pull never $IMAGE sh -c \
    'printf $TOOLCHAIN'
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}
