## Loki and Grafana

This Docker/Loki/Grafana setup is used to collect and visualize logs from the Docker containers.
The Loki driver is used to collect logs from the containers and send them to a Loki server, which stores the logs. Grafana is then used to visualize the logs stored in Loki.

Docker sends logs to the Loki server using the Loki driver. The logs are then stored in a local directory on the host machine, which is mounted as a volume in the Loki container. Grafana is then used to visualize the logs stored in Loki.

### Setup Loki

#### Create a loki-config.yaml file

See: `loki-config.yaml`

#### Create a docker-compose.yaml file

See: `logging-docker-compose.yml`

#### Start Loki

```bash
docker compose -f logging-docker-compose.yml up -d
```

#### Firewall
The firewall is configured to allow traffic on port 3100, which is the default port for Loki. This allows Grafana to access the Loki server and visualize the logs.

```bash
sudo ufw allow 3100/tcp
```

#### Install Docker Loki plugin

The Docker Loki plugin is installed via the command below. The plugin is installed with the `--grant-all-permissions` flag, which allows the plugin to access all Docker resources. The plugin is then enabled and the Docker daemon is restarted to apply the changes.

Check the latest version of the plugin on [grafana.com](https://grafana.com/docs/loki/latest/send-data/docker-driver/).

Change -amd64 to -arm64 in the image tag for ARM64 hosts.

```bash
docker plugin install grafana/loki-docker-driver:3.3.2-amd64 --alias loki --grant-all-permissions
```

##### update the plugin

```bash
docker plugin disable loki --force
docker plugin upgrade loki grafana/loki-docker-driver:3.3.2-amd64 --grant-all-permissions
docker plugin enable loki
systemctl restart docker
```

#### Configure Docker to use the Loki driver

Configure Docker to use the Loki driver by default for all containers.

This is done by creating a `daemon.json` file in the `/etc/docker/` directory and adding the following configuration:

This tells Docker that it should use the loki log driver instead of the default one and sends the logs to the Loki instance.

`loki-batch-size` is optional, but I like to set it to 400, meaning it will send 400 logs at a time to Loki. Not too many, not too few.

```json
{
  "log-driver": "loki",
  "log-opts": {
    "loki-url": "http://localhost:3100/loki/api/v1/push",
    "loki-batch-size": "400"
  }
}
```

#### Restart Docker

After configuring Docker to use the Loki driver, restart the Docker daemon to apply the changes.

```bash
sudo systemctl restart docker
```

### Configure Grafana
#### Add Loki as a data source
1. Open Grafana in your web browser.
2. Go to Configuration > Data Sources.
3. Click on "Add data source".
4. Select "Loki" from the list of available data sources.
5. In the URL field, enter `http://192.168.2.105:3100/loki/api/v1`.
6. Click "Save & Test" to save the data source and test the connection.
7. If the connection is successful, you should see a message indicating that the data source is working.
8. You can now use Loki as a data source in your Grafana dashboards.

#### Query logs in Grafana
1. Open Grafana in your web browser.
2. Go to the Explore tab.
3. Select the Loki data source from the dropdown menu.
4. In the query field, enter `{compose_project="skill"}` to filter logs from the `skill` project.
5. Click "Run Query" to see the logs from the `skill` project.
6. You can use the query editor to filter logs by container name, log level, and other parameters.

Source:

[Centralize and visualize Docker logs in Grafana with Loki](https://daniel.es/blog/centralize-and-visualize-docker-logs-in-grafana-with-loki/)

[grafana container](https://hub.docker.com/r/grafana/grafana)

[loki container](https://hub.docker.com/r/grafana/loki)
