#!/bin/bash

cd `dirname $0`
cd ..

readonly CURDIR=`pwd`
readonly RELEASE_DIR=${CURDIR}/dist/release

FILES=`find ${RELEASE_DIR}/proto -type f -name "*.ts" -or -name "*.js"`

for FILE in ${FILES}; do
    cp -Rf ${FILE} ${FILE/$RELEASE_DIR\//}
done
