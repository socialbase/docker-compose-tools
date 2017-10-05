#!/bin/bash

filename=$0
config_file=${filename##*/}

CONFIG=~/.${config_file}.conf

if [ ! -e $CONFIG ]; then
    echo "~/.${config_file}.conf not found"
    echo "Please run ./install.sh"
    exit 1
fi

source $CONFIG
source $DCT_DIR/functions.sh
cd $DC_DIR

args=$@

daemon=""
if [ ! -z "`echo $args |grep -e ' -d'`" ]; then
    daemon='-d'
fi
args=${args/" -d"}
args=${args/$1}

help () {
    echo "usage: $0 command <options>"
    echo -e "\tservices \tList services"
    echo -e "\trun      \tRun all services"
}

case "$1" in
    "services")
        list_services
        ;;
    "gen-env")
        gen_initial_files $DC_DIR $SRC_DIR
        ;;
    "config")
        run_docker_composer_cmd "config" $args
        ;;
    "run")
        run_docker_composer_cmd "up" $args
        ;;
    "build")
        run_docker_composer_cmd "build" $args
        ;;
    "pull")
        run_docker_composer_cmd "pull" $args
        ;;
    "stop")
        run_docker_composer_cmd "stop" $args
        ;;
    "help")
        help
        ;;
    *)
        help
        ;;
esac
