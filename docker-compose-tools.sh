#!/bin/bash

CONFIG=~/.docker-compose-tools.conf

if [ ! -e $CONFIG ]; then
    echo "~/.docker-compose-tools.conf not found"
    echo "Please run ./install.sh"
    exit 1
fi

source $CONFIG
source $DCT_DIR/functions.sh
cd $DC_DIR

args=$@

help () {
    echo "usage: $0 command <options>"
    echo -e "\tservices   \tList services"
    echo -e "\trun   \t\tRun all services, if set a service, this is run in dev mode"
}


case "$1" in
    "services")
        list_services
        ;;
    "help")
        help
        ;;
    "run")
        dev_services=${args/$1}
        prod=$(list_services)
        dev_files=""
        prod_files=""
        if [ ! -z "$dev_services" ]; then
            filter=$(echo $dev_services | sed -e 's/ /$\\|/g')
            filter="$filter\$"
            prod=$(list_services | grep -v "$filter")

            for i in $dev_services; do
                clone_service $i
                yml=$(get_param $i "dev")
                if [ "$yml" == "null" ]; then
                    echo "Key 'dev' not found in $i/service.json"
                    exit 1
                fi
                dev_files="${dev_files} -f ${i}/${yml}"
            done;
        fi

        if [ ! -z "$prod" ]; then
            for i in $prod; do
                yml=$(get_param $i "prod")
                if [ "$yml" == "null" ]; then
                    echo "Key 'prod' not found in $i/service.json"
                    exit 1
                fi
                prod_files="${prod_files} -f ${i}/${yml}"
            done;
        fi

        eval "docker-compose -f docker-compose.yml ${prod_files} ${dev_files} config"
        ;;
esac
