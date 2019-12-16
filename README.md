# CrushFTP for Docker

Docker image for CrushFTP server. Uses Ubuntu with openjdk-8-jre-headless and libmysql-java.

**Note:** This repository does not directly include any of the aforementioned copyrighted products, rather, it downloads them from the servers of their respective developers at buildtime. By using this container, you agree to any licence terms they may have.

This container, itself, is distributed under the [MIT Licence](LICENSE).

## Environment variables

| Variable               | Description              | Default      |
|:-----------------------|:-------------------------|:-------------|
| `CRUSH_ADMIN_USER`     | Admin user of CrushFTP   | `crushadmin` |
| `CRUSH_ADMIN_PASSWORD` | Password for admin user  | `crushadmin` |
| `CRUSH_ADMIN_PROTOCOL` | Protocol for admin       | `http`       |
| `CRUSH_ADMIN_PORT`     | Port for admin           | `8080`       |
| `CONNECT`              | Attempt to connect MySQL | `0`          |
| `MYSQL_HOST`           | MySQL host               | `db`         |
| `MYSQL_PORT`           | MySQL port               | `3306`       |
| `MYSQL_USER`           | MySQL user               | `crushftp`   |
| `MYSQL_PASSWORD`       | MySQL user password      | `crushftp`   |

## MySQL

If you set environment variable `CONNECT` to `1` then this container will try to setup and connect to a MySQL server for user config and logging.

See docker-compose.yml for example.

## Installation

Run this container and share the containers `/var/opt/CrushFTP9` directory, which persists CrushFTP's configuration, to an appropriate location on the host. Open a browser and go to http://localhost:8080. Note that the default username and password are both `crushadmin`.

This command will create a new container and expose http on port 8080 and SFTP on port 2222. Remember to change the `<volume>` to a location on your host machine.

```
docker run -p 8080:8080 -p 2222:2222 -v <volume>:/var/opt/CrushFTP9 snoophogg/crushftp:latest
```
