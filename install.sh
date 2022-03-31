#!/bin/bash

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/docker_check.sh

set +o noglob

usage=$'Please set variable and other necessary attributes in docker-compose.yml file first. DO NOT use localhost or 127.0.0.1 for hostname, because Docker needs to be accessed by external clients.
Please set --with-build if needs build a dockerfile image'
item=0

# docker image is not build by default
with_build=$false

while [ $# -gt 0 ]; do
        case $1 in
            --help)
            note "$usage"
            exit 0;;
            --with-build)
            with_build=true;;
            *)
            note "$usage"
            exit 1;;
        esac
        shift || true
done

workdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $workdir

h2 "[Step $item]: checking if docker is installed ..."; let item+=1
check_docker

h2 "[Step $item]: checking docker-compose is installed ..."; let item+=1
check_dockercompose

if [ -f *.tar.gz ]
then
    h2 "[Step $item]: loading oracle images ..."; let item+=1
    docker load -i ./*.tar.gz
fi
echo ""

if [ $with_build ]
then
     h2 "[Step $item]: building docker image ...";  let item+=1
    ./buildContainerImage.sh " --t database:19.3.0-se2 -i"
fi

if [ -n "$(docker-compose ps -q)"  ]
then
    h2 "[Step $item]: stopping docker-compose ...";  let item+=1
    note "stopping existing docker-compose instance ..."
    docker-compose down -v
fi

h2 "[Step $item]: starting docker-compose ..."
docker-compose up -d

success $"----Docker images has been installed and started successfully.----"
