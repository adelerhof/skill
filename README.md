## hostname and ip

```text
skill.blaataap.com
2a00:1d38:f8::105
178.20.173.141
```

## change hostname
```bash
/etc/hostname
/etc/hosts
```

## change ip

```bash
vi /etc/netplan/00-installer-config.yaml
netplan apply
```
## update

```bash
apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade && sudo apt-get autoremove
```

## install docker components

- docker
- podman
- buildah
- skopeo

```bash
sudo apt-get -y install podman buildah skopeo
```

## Docker

[Docker installation](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

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

## GitHub actions

### Self-hosted runner

#### Add user

```bash
useradd -m -G sudo docker -s /bin/bash ghrunner
```

### Install runner

[Adding self-hosted runners - GitHub Docs](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)


## Used stack

### Prerequisites:

1. **Local Runner Accessibility:** Your local GitHub runner machine _must_ be accessible from the public internet on ports 80 (for Let's Encrypt HTTP validation) and 443 (for HTTPS traffic). This usually involves:
    - Configuring your router/firewall to forward incoming traffic on ports 80 and 443 to the _internal IP address_ of your local runner machine.
    - Ensuring any firewall software on the runner machine itself allows incoming connections on ports 80 and 443.
2. **DNS Record:** You need a DNS A record for `skill.blaataap.com` pointing to the _public IP address_ of the network where your local runner is located.
3. **Docker and Docker Compose:** Ensure Docker and Docker Compose V2 are installed and working correctly on your local runner machine.

### Approach: `nginx-proxy` + `acme-companion`

This is a popular and well-maintained solution using two specialized Docker images:

- `nginx-proxy`: Automatically discovers running containers and configures Nginx to proxy traffic to them based on environment variables.
- `acme-companion`: Works alongside `nginx-proxy` to automatically obtain and renew Let's Encrypt certificates for the proxied containers.

#### docker-compose.yml

**Modify your `docker-compose.yml`:** You'll add the `nginx-proxy` and `letsencrypt-companion` services alongside your application service (`skill` in this case ).

#### Explanation of Key Parts:

- **`services.nginx-proxy`:**
    - `ports: ["80:80", "443:443"]`: Exposes Nginx on the host machine's standard HTTP/S ports. Traffic coming to your runner on these ports will hit this container.
    - `volumes`: `/var/run/docker.sock` allows it to inspect other Docker containers. `certs`, `vhostd`, `html` are shared volumes for certificates, Nginx configs, and Let's Encrypt challenge files. Using named volumes (`certs:`, etc.) makes them persistent.
    - `networks: [webproxy]`: Connects it to the custom bridge network.
- **`services.letsencrypt-companion`:**
    - `volumes`: Shares the same volumes as `nginx-proxy` plus the Docker socket. Needs read-write (`rw`) on `certs` to store them.
    - `environment.NGINX_PROXY_CONTAINER`: Tells the companion which proxy container to configure (must match the `container_name` or service name of the proxy).
    - `environment.DEFAULT_EMAIL`: Your email for Let's Encrypt registration and expiry notifications.
    - `depends_on: [nginx-proxy]`: Ensures the proxy starts before the companion tries to interact with it (optional but good practice).
- **`services.skill`:**
    - `environment.VIRTUAL_HOST`: Tells `nginx-proxy` which domain name should route to this container.
    - `environment.LETSENCRYPT_HOST`: Tells `acme-companion` to get a certificate for this domain for this container.
    - `environment.LETSENCRYPT_EMAIL`: Specific email for this certificate (overrides `DEFAULT_EMAIL`). **Crucial** for registration.
    - `expose: ["80"]`: **Important:** Use `expose` to declare the internal port your application listens on. _Do not_ use `ports:` to map it directly to the host, as `nginx-proxy` handles the connection _within_ the Docker network.
    - `networks: [webproxy]`: Connects your app to the same network as the proxy, allowing `nginx-proxy` to reach it using the service name (`webapp` in this case) and the exposed port (`8000`).
- **`networks.webproxy`:** Defines a custom bridge network. This is recommended over the default network for better isolation and service discovery by container name.
- **`volumes`:** Defines named volumes to persist certificates and configurations even if containers are removed and recreated.

#### GitHub Action Workflow: Your GitHub Action step that runs on the local runner simply needs to bring up the services using Docker Compose.

`.github/workflows/image.yml`

#### How it Works:

1. The GitHub Action runs `docker compose up -d`.
2. Docker Compose starts `nginx-proxy`, `letsencrypt-companion`, and the `skill` webapp.
3. `nginx-proxy` detects the `skill` container via the Docker socket and sees the `VIRTUAL_HOST` variable. It generates an Nginx configuration to proxy requests for `skill.blaataap.com` to `webapp:80` over the `webproxy` network.
4. `letsencrypt-companion` detects the `skill` container and sees the `LETSENCRYPT_HOST` variable.
5. It initiates the Let's Encrypt validation process (usually HTTP-01). It places the necessary challenge file within the shared `html` volume.
6. `nginx-proxy` is already configured by the companion to serve these challenge files correctly from port 80.
7. Let's Encrypt's servers access `http://skill.blaataap.com/.well-known/acme-challenge/...`, hit your runner's public IP, get forwarded to the `nginx-proxy` container, which serves the file.
8. Validation succeeds, Let's Encrypt issues a certificate.
9. `letsencrypt-companion` places the certificate and key into the shared `certs` volume.
10. `nginx-proxy` automatically detects the new certificate and reloads its configuration to start using HTTPS for `skill.blaataap.com`.
11. The companion container periodically checks certificates and renews them automatically before they expire.

## References

Source:

[Adding self-hosted runners - GitHub Docs](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)
[Docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
[Docker compose](https://docs.docker.com/compose/gettingstarted/)
[Networking With Docker Compose](https://www.netmaker.io/resources/docker-compose-network)
[nginxproxy-acme-companion](https://hub.docker.com/r/nginxproxy/acme-companion#:~:text=It%20handles%20the%20automated%20creation,containers%20through%20the%20ACME%20protocol.)
[nginxproxy/nginx-proxy]([nginxproxy/nginx-proxy - Docker Image | Docker Hub](https://hub.docker.com/r/nginxproxy/nginx-proxy))

