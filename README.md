# skill
Collection for Future Skills

Apparmor!!
## hostname and ip

skill.blaataap.com
2a00:1d38:f8::105
178.20.173.141

ubuntu 22.04
## change hostname
/etc/hostname
/etc/hosts

## change ip

vi /etc/netplan/00-installer-config.yaml
netplan apply
k8srancher	178.20.173.149	2a00:1d38:f8::149

## update

apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade && sudo apt-get autoremove

## install docker components

- docker
- podman
- buildah
- skopeo

```bash
sudo apt-get -y install podman buildah skopeo
```

## docker

https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

### Add Docker's official GPG key:
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### Add the repository to Apt sources:
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

### Install the Docker packages.

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

```bash
sudo docker run hello-world
```


```bash
unable to get image 'redis:alpine': permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock:
```

## login dockerhub

```bash
docker login docker.io
```


## set permissions for regular users

[Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)

```bash
sudo groupadd docker
sudo usermod -aG docker $USER

```

## docker compose
### Install Docker compose

https://docs.docker.com/compose/install/linux/#install-using-the-repository

```bash
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

```bash
docker compose version
```

### First docker compose test

https://docs.docker.com/compose/gettingstarted/

```bash
docker compose up
docker compose down
```

#### test

```bash
curl http://skill.blaataap.com:8000
```

```bash
docker image ls

```

### docker compose watch

```console
docker compose watch
```

### useful commands

```bash
docker compose up -d
docker compose ps
docker compose stop # keeps the containers
docker compose down # remove the containers, so storage/status is gone
```

```bash

curl http://skill.blaataap.com:8000
Hello Blaataap! I have been seen 1 times.
curl http://skill.blaataap.com:8000
Hello Blaataap! I have been seen 2 times.

```