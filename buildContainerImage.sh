#!/bin/bash
set -e

# BUILD THE IMAGE
BUILD_START=$(date '+%s')
docker build --force-rm=true --no-cache=true \
       --build-arg DB_EDITION=se2 \
       -t oracle/database:19.3.0-se2 -f Dockerfile . || {
  echo ""
  echo "ERROR: Oracle Database container image was NOT successfully created."
  echo "ERROR: Check the output and correct any reported problems with the build operation."
  exit 1
}
# Remove dangling images (intermitten images with tag <none>)
yes | docker image prune > /dev/null
BUILD_END=$(date '+%s')
BUILD_ELAPSED=$(( BUILD_END - BUILD_START ))
echo ""
echo ""
cat << EOF
  Oracle Database container image for oracle standard edition version 19.3.0 is ready to be extended:
    --> ${IMAGE_NAME}
  Build completed in ${BUILD_ELAPSED} seconds.
EOF
