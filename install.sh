#!/bin/bash

source $(pwd)/functions.sh
dct_dir=$(pwd)
dc_dir=$1
src_dir=$2
executable=$3

if [ -z $src_dir ] || [ -z $dc_dir ]; then
    echo "usage: $0 docker-compse-dir src-dir <executable-name>";
    exit 1;
fi

if [ -z $executable ]; then
    executable="dc-tools"
fi

conf="~/.${executable}.conf"

echo "DC_DIR=${dc_dir}" > ~/.${executable}.conf
echo "DCT_DIR=${dct_dir}" >> ~/.${executable}.conf
echo "SRC_DIR=${src_dir}" >> ~/.${executable}.conf

gen_initial_files $dc_dir $src_dir

sudo ln -fs ${dct_dir}/docker-compose-tools.sh /usr/local/bin/$executable
echo "${executable} installed"
