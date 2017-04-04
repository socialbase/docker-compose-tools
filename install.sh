#!/bin/bash

source $(pwd)/functions.sh
dct_dir=$(pwd)
dc_dir=$(pwd)/..
src_dir=$1
executable=$2

if [ -z $src_dir ]; then
    echo "usage: $0 docker-compse-dir src-dir <executable-name>";
    exit 1;
fi

if [ -z $executable ]; then
    executable="dc-tools"
fi

echo "DC_DIR=${dc_dir}" > ~/.docker-compose-tools.conf
echo "DCT_DIR=${dct_dir}" >> ~/.docker-compose-tools.conf
echo "SRC_DIR=${src_dir}" >> ~/.docker-compose-tools.conf

dir=$(pwd)
cd $dc_dir

if [ -f $dc_dir/.env ]; then
    rm $dc_dir/.env
fi

cd $dc_dir
for i in $(list_services); do
    tmp_dir=${src_dir}$(get_param $i "dir")
    echo "${i^^}_TAG=latest" >> $dc_dir/.env
    echo "${i^^}_DIR=${tmp_dir}" >> $dc_dir/.env
done

sudo ln -fs ${dir}/docker-compose-tools.sh /usr/local/bin/$executable
if [ $? ]; then
    echo "Install failed"
    exit 1;
fi
echo "${executable} installed"
