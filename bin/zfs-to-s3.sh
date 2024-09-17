#! /usr/bin/env nix-shell
#! nix-shell -i bash -p awscli2 zfs

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" ; pwd)"

source "${SCRIPT_DIR}/functions.sh"

DATASETS=($(zfs get -t filesystem s3:garage -o name,value -H -r d/service | grep [[:space:]]true$ | awk '{print $1}'))

for d in "${DATASETS[@]}"
do
  echo "Backing up ${d}"
  SOURCE_SNAPSHOTS=($(zfs list -H -o name -t snapshot ${d} | grep -v @clam | sed 's/.*@//'))

  AWS_ACCESS_KEY_ID='GK77fcfc83cb9fdc3e7e561f9d'
  AWS_SECRET_ACCESS_KEY='c51528bae0425cb3547662707f924c6b142b784068981807e2520a7c67f9d759'
  AWS_DEFAULT_REGION='garage'
  AWS_ENDPOINT_URL='http://garage.home.gustafson.me:3900'

  TARGET_FILES=($(aws s3 ls s3://backup/$(hostname)/${d}/_/ | awk '{print $4}'))

  PREVIOUS_SNAPSHOT=""
  for s in "${SOURCE_SNAPSHOTS[@]}"
  do
    if ! ((for f in "${TARGET_FILES[@]}"; do echo ${f}; done) | grep -e "^${s}~" -e "^${s}$")
    then
      INCREMENTAL=""
      [[ "${PREVIOUS_SNAPSHOT}" == "" ]] || INCREMENTAL="-i ${d}@${PREVIOUS_SNAPSHOT}"
      TARGET_FILE="${s}"
      [[ "${PREVIOUS_SNAPSHOT}" == "" ]] || TARGET_FILE="${s}~${PREVIOUS_SNAPSHOT}"
      # echo "zfs send -v ${INCREMENTAL} ${d}@${s} | zstd -15 -T0 --auto-threads=logical | aws s3 cp - s3://backup/$(hostname)/${d}/_/${TARGET_FILE}"
      zfs send -v ${INCREMENTAL} ${d}@${s} | zstd --long -T0 --auto-threads=logical -15 | aws s3 cp - s3://backup/$(hostname)/${d}/_/${TARGET_FILE}
    fi
    PREVIOUS_SNAPSHOT="${s}"
  done
done
