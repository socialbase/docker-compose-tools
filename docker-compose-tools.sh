#!/bin/bash

CONFIG=~/.docker-compose-tools.conf

if [ ! -e $CONFIG ]; then
    echo "~/.docker-compose-tools.conf not found";
    echo "Please run ./install.sh";
    exit 1;
fi

source $CONFIG;
cd $DC_DIR;

CMDS=commands
if [ ! -f $CMDS ]; then
    echo -e "{" > $CMDS;
    echo -e "\t\"logs\": \"docker logs {{container}}\"," >> $CMDS;
    echo -e "\t\"exec\": \"docker exec -it {{container}} bash\"" >> $CMDS;
    echo -e "}" >> $CMDS;
fi

args=$@

help () {
    echo "usage: $0 command <options>";
    echo -e "\tlist   \tList services";
    echo -e "\tclone \tClone services";
    echo -e "\trun   \tRun all services, if set a service, this is run in dev mode";
    if [ -f $CMDS ]; then
        for i in $(jq 'keys[]' $CMDS); do
            cmd=$(echo $i | sed -e 's/"//g')
            cmd="${cmd}\t"
            line=`cat $CMDS | jq ".$i"`
            if [ -z "$(echo $line |grep -v '{{container}}')" ]; then
                cmd="${cmd}service "
            fi
            if [ -z "$(echo $line |grep -v '{{args}}')" ]; then
                cmd="${cmd}arguments"
            fi
            echo -e "\t${cmd}"
        done
    fi
}

get_param () {
    service=$1
    key=$2
    ret=$(cat services/${service}/service.json |jq ".${key}"| sed -e 's/"//g')
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

case "$1" in
    "services")
        ls -1 services
        ;;
    "clone")
        clone
        ;;
    "help")
        help
        ;;
    "run")
        dev_services=${args/$1}
        prod=$(ls -1 services)
        dev_files=""
        prod_files=""
        if [ ! -z "$dev_services" ]; then
            filter=$(echo $dev_services | sed -e 's/ /$\\|/g')
            filter="$filter\$"
            prod=$(ls -1 services | grep -v "$filter")

            for i in $dev_services; do
                clone_service $i
                yml=$(get_param $i "dev")
                if [ "$yml" == "null" ]; then
                    echo "Key 'dev' not found in $i/service.json"
                    exit 1
                fi
                dev_files="${dev_files} -f services/${i}/${yml}"
            done;
        fi

        if [ ! -z "$prod" ]; then
            for i in $prod; do
                yml=$(get_param $i "prod")
                if [ "$yml" == "null" ]; then
                    echo "Key 'prod' not found in $i/service.json"
                    exit 1
                fi
                prod_files="${prod_files} -f services/${i}/${yml}"
            done;
        fi

        eval "docker-compose -f docker-compose.yml ${prod_files} ${dev_files} up"
        ;;
    *)
        if [ ! -f $CMDS ]; then
            help;
        fi
        if [ -z $1 ]; then
            help;
            exit 1;
        fi
        CONTAINER=''
        e=`cat $CMDS | jq ".$1" | sed -e 's/\"//g' |grep '{{container}}'`
        if [ "$e" != "" ]; then
            if [ -z $2 ]; then
                echo "usage: $0 $1 service"
                exit 1
            fi
            CONTAINER=`get_container $2`
            if [ -z $CONTAINER ]; then
                echo "Service $2 not found or not running"
                exit 1
            fi
        fi
        delete=("$2")
        args=${args/$delete}
        args=${args//\//\\/}
        cmd=`cat $CMDS | jq ".$1" | sed -e 's/\"//g' |sed -e "s/{{container}}/${CONTAINER}/" |sed -e "s/{{args}}/${args}/"`
        if [ "$cmd" == "null" ]; then
            echo "commando $1 not found";
            exit 1;
        fi
        echo "exec: $cmd"
        eval $cmd
        ;;
esac
