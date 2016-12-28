#!/bin/bash

dc_dir=$1
src_dir=$2
executable=$3

if [ -z $dc_dir ] || [ -z $src_dir ]; then
    echo "usage: $0 docker-compse-dir src-dir <executable-name>";
    exit 1;
fi

if [ -z $executable ]; then
    executable="dc-tools"
fi

echo "DC_DIR=${dc_dir}" > ~/.docker-compose-tools.conf
echo "SRC_DIR=${src_dir}" >> ~/.docker-compose-tools.conf

sudo ln -fs $(pwd)/docker-compose-tools.sh /usr/local/bin/$executable
echo "${executable} installed"
