# docker-compose-tools

## Install

```
git clone git@github.com:darkSasori/docker-compose-tools.git
cd docker-compose-tools
./install.sh ~/src/docker ~/src
```

## Struct Example
Files:
```
commands
docker-compose.yml
 - services
   - web
     - service.json
     - dev.yml
     - prod.yml
   - db
     - service.json
     - dev.yml
     - prod.yml
```

### File
commands:
```
{
	"logs": "docker logs {{container}}",
	"exec": "docker exec -it {{container}} bash"
}
```

docker-compose.yml:
```
version: '2'

services:
    web:
        ports:
            - 81:80
        networks:
            - net

    db:
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
    "git": "git@github.com:darkSasori/docker-compose-tools.git",
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
        image: nginx
        environment:
            env: "PROD"
```
web/dev.yml:
```
version: '2'

services:
    web:
        image: nginx
        environment:
            env: "DEV"
```

## Usage Example
Help:
```
dc-tools help
```

Run with web in dev mode and db in prod mode:
```
dc-tools run web
```
