#!/usr/bin/env bash

usage="Usage: $(basename "$0") stack-name [aws-cli-opts]

where:
  stack-name   - the stack name
  aws-cli-opts - extra options passed directly to create-stack/update-stack
"

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "usage" ] ; then
  echo "$usage"
  exit -1
fi

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "$usage"
  exit -1
fi

set -eu pipefail

echo "Checking if stack exists ..."

if ! aws cloudformation describe-stacks --stack-name $1 ; then

  echo -e "\nStack does not exist, creating ..."
  aws cloudformation create-stack --stack-name $1 $2\

  echo "Waiting for stack to be created ..."
  aws cloudformation wait stack-create-complete --stack-name $1 \

else

  echo -e "\nStack exists, attempting update ..."
  set +e
  aws cloudformation describe-stacks --stack-name $1 | grep -x "ROLLBACK_COMPLETE"
  if [[ $? == 0 ]]; then
    echo -e "\nStack in ROLLBACK_COMPLETE, attempting to delete ..."
    aws cloudformation delete-stack --stack-name $1\

    echo "Waiting for stack to be deleted ..."
    aws cloudformation wait stack-delete-complete --stack-name $1\

    echo "stack deleted, creating the new one ..."
    aws cloudformation create-stack --stack-name $1 $2\

    echo "Waiting for stack to be created ..."
    aws cloudformation wait stack-create-complete --stack-name $1 \

    echo "Stack created"
  fi
  update_output=$( aws cloudformation update-stack --stack-name $1 $2)
  status=$?
  set -e

  if [ $status -ne 0 ] ; then
    echo $status
    # Don't fail for no-op update
    if [ $status == 255 ] ; then
      echo -e "\nFinished create/update - no updates to be performed"
      exit 0
    else
      exit $status
    fi

  fi

  echo "Waiting for stack update to complete ..."
  aws cloudformation wait stack-update-complete --stack-name $1 \

fi

echo "Finished create/update successfully!"
