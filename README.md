# picachu-infra

## Description
A project about deploy picachu services in cluster

## Local development

### Prerequisites

1. `docker desktop`
    you can install it on different operating system through the link
    https://www.docker.com/products/docker-desktop/

2.  For windows you need to install `choco` package manager 
    open your powershell with admin rights and write command - 
    ```
    Get-ExecutionPolicy
    ```
    If it returns "Restricted", then run 
    ```
    Set-ExecutionPolicy AllSigned
    ```
    or 
    ```
    Set-ExecutionPolicy Bypass -Scope Process.
    ```
    Then run the following command
    ```
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    ```
    To check that choco installed correctly run this
    ```
    choco
    ```

3. `make`
   - ***Linux:*** `make` should be installed automatically.
   - ***MacOS:*** `make` should be installed automatically.
   - ***Windows:***
     on Windows install using chocolatey (if you use git bash cmd it should be run as Administrator)
     ```bash
     choco install make
     ```

### How to run local deploy

First, you need to install neccessarly packages
```bash
make install-dependency
```
For deleting all installed dependencies 
```bash
make uninstall-dependency
```

To create cluster you need have running docker daemon, so for that you need start your installed docker desktop. Then type command for creating local cluster.
```bash
make create-cluster
```
For deleting cluster 
```bash
make delete-cluster
```

To deploy all services in local cluster run this, but for normal work you need to specify variables in .env file
(see .env.example)
```bash
make local-deploy
```

you can access to services through portforwarding or hostdomains

#### Map

| Service                   | domain                                           |
|---------------------------|--------------------------------------------------|
| picachu-ui                | picachu.local.tourmalinecore.internal            |
| picachu-api               | picachu.local.tourmalinecore.internal/api        |
| picachu-api-s3-console    | s3-console.picachu.local.tourmalinecore.internal |
| picachu-api-s3            | s3.picachu.local.tourmalinecore.internal         |
| picachu-api-postgres      | localhost:30100                                  |
| picachu-api-rabbitmq      | localhost:30106                                  |

For now you also can clone/update api and ui repos through make in current folder.
```bash
make clone-repo
```
```bash
make update-repo
```
Authentication to github repos achieved by your ssh-key from .env, we strogly recommend
encode your ssh-key with passphrase.
