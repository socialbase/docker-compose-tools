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
            prod_files=$(get_prod_files $prod);
        fi

        eval "docker-compose -f docker-compose.yml ${prod_files} ${dev_files} config"
        ;;
    "homolog")
        homologs=${args/$1}
        prod_files=$(get_prod_files)
        env=""
        for i in $homologs; do
            service=$(echo $i |cut -d'=' -f1);
            tag=$(echo $i |cut -d'=' -f2);
            env="${env}${service^^}_TAG=${tag} "
        done;
        eval "${env}docker-compose -f docker-compose.yml ${prod_files} config"
        ;;
    "help")
        help
        ;;
    *)
        help
        ;;
esac
