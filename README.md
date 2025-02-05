# Verkada Helix Data Bridge

Middleware to translate structured data for use with Verkada Helix.

## Description

This middleware translates data from various business systems into a format compatible with Verkada Helix. It functions as a bridge between your business systems and Verkada Helix, allowing you to map your data to camera footage and
access business events from within Verkada Command.

## Features

* Accepts JSON post requests containing data from business systems.
* Transforms the data based on rules defined in a user-uploaded CSV file.
* Forwards the transformed data to a Verkada Command.
* Provides a web interface for uploading and managing configuration files.
* Automatically creates Helix event types based on the supplied configuration file.
* Can be deployed manually or using any OCI compliant container orchestrator. 
* Easy deployment with pre-built container images at: `ghcr.io/0xconnorrhodes/helix-data-bridge`.

## Requirements

* OCI compatible container engine (e.g. Docker, Podman, Kubernetes, etc.)
* A Verkada Command org with Helix enabled.
* An API key with the following permissions: 
    - Read-Only permissions to the Core Command endpoints. (Used to get the relevant org id)
    - Read-Only permissions to Camera endpoints. (Used to validate camera IDs)
    - Read-Write permissions to the Helix endpoints. (Used to create Helix events and event types.)

## Setup

### 1. deploy container compose stack (Docker)

Inside the `deploy` directory, run `docker compose up -d` to start the desired container compose stack. 
- `compose-basic` runs on the local network using HTTP. 
- `compose-https` runs with self-signed HTTPS certificates.
- `container-build` can be used to to build the container image locally.

**Note**: ensure you have changed the `ADMIN_USERNAME` and `ADMIN_PASSWORD` environment variables in the `compose-basic` and `compose-https` files to the desired values.

### 2. configure the data bridge

Navigate to the web interface of the data bridge and log in using the credentials supplied in the `compose.yml` file. Upload your API key and the necessary configuration files in the web interface.

Note that a `.env` file with your API key and the configuration files may be mounted into the container to configure the container at boot. See the commented lines in `compose.yml` for examples.

For more information on the format of the required configuration files, see the documentation pages linked in the Data Bridge web interface.

### 3. Configure business systems

Configure your business systems to send data to the data bridge.
The data should be sent as a POST request to: `http://<data-bridge-ip>/event/by/keyid`.

The body of the request should be a JSON object with a format matching the format specified in the event types configuration file.

Note that if you are using the `compose-https` stack, you will need to send requests using the `https://` protocol and ensure that your business systems will connect to a server with a self-signed certificate. 
If a truested certificate is required, you can proxy requests to the Data Bridge from a reverse proxy that provides a trusted certificate for your domain.


## Disclaimer

This is a community project and is not officially affiliated with, endorsed by, or supported by Verkada Inc. While care has been taken to ensure proper functionality and error handling, this software is provided "as is" without warranty of any kind, express or implied. The creators and contributors of this project make no guarantees about its operation or reliability. Users of this middleware assume all responsibility and risk associated with its use. Any outcome resulting from the use of this software is solely the responsibility of the user.