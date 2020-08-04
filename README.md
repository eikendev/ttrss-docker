[![Docker Pulls](https://img.shields.io/docker/pulls/eikendev/ttrss-docker)](https://hub.docker.com/r/eikendev/ttrss-docker)

## About

This is my personal [Docker](https://www.docker.com/) image for [Tiny Tiny RSS](https://tt-rss.org/).
It is based on the official PHP image and will update automatically if its base image updates.

As with my [Nextcloud image](https://github.com/eikendev/nextcloud-docker), I'm very concerned with security and want to enforce tight permission policies.
To me it was important that
- the file permissions of the installation are set as strictly as possible, and
- the web server runs under a non-privileged user.

## Usage

The following Docker Compose configuration should give you an idea on how to use this image.
```yaml
version: '2'

services:
    server:
        image: eikendev/ttrss
        tty: true
        ports:
            - 8080:8080
        volumes:
            - ./mount/configuration:/volume/configuration
            - ./mount/plugins:/volume/plugins
            - ./mount/themes:/volume/themes

    updater:
        image: eikendev/ttrss
        tty: true
        user: www-data
        entrypoint: php ./update_daemon2.php
        volumes:
            - ./mount/configuration:/volume/configuration
            - ./mount/plugins:/volume/plugins
            - ./mount/themes:/volume/themes
```
