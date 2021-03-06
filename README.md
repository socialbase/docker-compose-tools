# docker-compose-tools

## Install

```
git clone git@github.com:socialbase/docker-compose-tools.git
cd docker-compose-tools
./install.sh ~/src/docker ~/src
```

## Commands

- services
- config
- run
- build
- pull
- stop

## Struct Example
```
docker-compose.yml
 - services
   - web
     - service.json
     - dev.yml
     - prod.yml
```

### File
docker-compose.yml:
```
version: '2'

services:
    web:
        image: nginx
        ports:
            - 81:80
        networks:
            - net

    db:
		image: mysql:latest
        ports:
            - 5432:5432
        networks:
            - net

networks:
    net:
        driver: bridge
        ipam:
            driver: default
            config:
            - subnet: 172.18.0.0/24
              gateway: 172.18.0.1
```

web/service.json:
```
{
    "git": "git@github.com:socialbase/docker-compose-tools.git",
    "dir": "docker-compose-tools",
    "prod": "prod.yml",
    "dev": "dev.yml"
}
```

web/prod.yml:
```
version: '2'

services:
    web:
        environment:
            env: "PROD"
```
web/dev.yml:
```
version: '2'

services:
    web:
        environment:
            env: "DEV"
```
