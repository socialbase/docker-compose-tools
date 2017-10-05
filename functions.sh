#!/bin/bash

get_param () {
    service=$1
    key=$2
    ret=$(cat ${service}/service.json |jq ".${key}"| sed -e 's/"//g')
    if [ "$ret" == "null" ] || [ -z $ret ]; then
        return 1;
    fi
    echo $ret
}

get_container() {
    docker ps -f name=$1 |grep docker |cut -d" " -f1
}

clone () {
    echo "Clone";
    for i in $(ls -1 services); do
        clone_service $i;
    done;
}

clone_service () {
    git=$(get_param $1 "git")
    if [ $? ]; then
        return 1
    fi
    dir=${SRC_DIR}$(get_param $1 "dir")
    if [ ! -d "${dir}" ]; then
        git clone $git ${dir}
    fi
}

list_services () {
    for i in $(ls -d */ |cut -f1 -d'/'); do
        if [ -f "${i}/service.json" ]; then
            echo $i;
        fi;
    done;
}

get_prod_files () {
    list_prod=$1
    if [ -z $list_prod ]; then
        list_prod=$(list_services)
    fi
    for i in $list_prod; do
        yml=$(get_param $i "prod")
        if [ "$yml" == "null" ]; then
            echo "Key 'prod' not found in $i/service.json"
            exit 1
        fi
        prod_files="${prod_files} -f ${i}/${yml}"
    done;
    echo $prod_files
}

gen_initial_files() {
    dc_dir=$1
    src_dir=$2

    cd $dc_dir

    if [ -f $dc_dir/.env ]; then
        rm $dc_dir/.env
    fi

    echo "SRC_DIR=${src_dir}" > $dc_dir/.env
    echo "DC_DIR=${src_dir}" >> $dc_dir/.env

    for i in $(list_services); do
        tmp_dir=${src_dir}$(get_param $i "dir")
        echo "${i^^}_TAG=latest" >> $dc_dir/.env
        echo "${i^^}_DIR=${tmp_dir}" >> $dc_dir/.env
    done
}

run_docker_composer_cmd() {
    dev_services=$@
    dev_services=${dev_services/$1}
    prod=$(list_services)
    dev_files=""
    prod_files=""
    env=""
    up=""
    if [ ! -z "$dev_services" ]; then
        filter=$(echo $dev_services | sed -e 's/ /$\\|/g')
        filter="$filter\$"
        prod=$(list_services | grep -v "$filter")

        for i in $dev_services; do
            if [ ! -z $(echo $i |grep '^+') ]; then
                up="${up} $(echo $i |sed -e 's/+//g')";
                continue;
            elif [ ! -z $(echo $i |grep =) ]; then
                service=$(echo $i |cut -d'=' -f1);
                tag=$(echo $i |cut -d'=' -f2);

                env="${env}${service^^}=${tag} "
                continue;
            fi;
            clone_service $i
            yml=$(get_param $i "dev")
            if [ $? -ne 0 ] || [ ! -f "${i}/${yml}" ]; then
                echo "Key 'dev' not found in $i/service.json, using prod"
                yml=$(get_param $i "prod")
                if [ $? -ne 0 ] || [ ! -f "${i}/${yml}" ]; then
                echo "Key 'dev' not found in $i/service.json"
                    continue;
                fi;
            fi;
            dev_files="${dev_files} -f ${i}/${yml}"
        done;
    fi

    if [ ! -z "$prod" ]; then
        prod_files=$(get_prod_files $prod);
    fi
    echo "${env}docker-compose -f docker-compose.yml ${prod_files} ${dev_files} $1 ${daemon} ${up}"
}
