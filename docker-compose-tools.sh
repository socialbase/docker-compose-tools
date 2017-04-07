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
    echo -e "\tservices \tList services"
    echo -e "\trun      \tRun all services, if set a service, this is run in dev mode"
    echo -e "\thomolog  \tRun specific tag of container. Ex: API=pr-2"
}


case "$1" in
    "services")
        list_services
        ;;
    "run")
        dev_services=${args/$1}
        prod=$(list_services)
        dev_files=""
        prod_files=""
        env=""
        if [ ! -z "$dev_services" ]; then
            filter=$(echo $dev_services | sed -e 's/ /$\\|/g')
            filter="$filter\$"
            prod=$(list_services | grep -v "$filter")

            for i in $dev_services; do
                if [ ! -z $(echo $i |grep =) ]; then
                    service=$(echo $i |cut -d'=' -f1);
                    tag=$(echo $i |cut -d'=' -f2);
                    env="${env}${service^^}_TAG=${tag} "
                    continue;
                fi;
                clone_service $i
                yml=$(get_param $i "dev")
                if [ $? -ne 0 ] || [ ! -f "${i}/${yml}" ]; then
                    echo "Key 'dev' not found in $i/service.json, using prod"
                    yml=$(get_param $i "prod")
                fi
                dev_files="${dev_files} -f ${i}/${yml}"
            done;
        fi

        if [ ! -z "$prod" ]; then
            prod_files=$(get_prod_files $prod);
        fi
        eval "${env} docker-compose -f docker-compose.yml ${prod_files} ${dev_files} config"
        ;;
    "help")
        help
        ;;
    *)
        help
        ;;
esac
