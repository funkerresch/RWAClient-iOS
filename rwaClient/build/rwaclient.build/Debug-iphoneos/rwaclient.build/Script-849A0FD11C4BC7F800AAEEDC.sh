#!/bin/sh
find -L "${PROJECT_DIR}/../rwaGames" \
-type f -not -name ".*" \
| xargs -t -I {} \
rsync -auv {} ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/

