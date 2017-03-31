#!/bin/bash

get_param () {
    service=$1
    key=$2
    ret=$(cat ${service}/service.json |jq ".${key}"| sed -e 's/"//g')
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
    dir=${SRC_DIR}$(get_param $1 "dir")
    if [ ! -d "${dir}" ]; then
        git clone $git ${dir}
    fi
}

list_services () {
    ls -d */ |grep -v .git |cut -f1 -d'/'
}