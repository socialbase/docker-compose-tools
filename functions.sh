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
    ls -d */ |grep -v .git |cut -f1 -d'/'
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
