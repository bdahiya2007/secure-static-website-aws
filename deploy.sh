#!/usr/bin/env bash
#
# deploy.sh
#
# Uploads local website files to the S3 bucket created by
# s3-static-website.yaml.
#
# Usage:
#   ./deploy.sh [bucket-name] [local-folder] [--delete]
#   ./deploy.sh [bucket-name] --empty
#
# Examples:
#   ./deploy.sh
#   ./deploy.sh bdahiya-ecommerce-static-website
#   ./deploy.sh bdahiya-ecommerce-static-website ./s3-static-website
#   ./deploy.sh bdahiya-ecommerce-static-website ./s3-static-website --delete
#   ./deploy.sh bdahiya-ecommerce-static-website --empty
#
# Arguments:
#   bucket-name    Optional. Name of the target S3 bucket.
#                  Defaults to bdahiya-ecommerce-static-website
#   local-folder   Optional. Local folder to upload. Defaults to ./s3-static-website
#   --delete       Optional. Also removes files from the bucket that no
#                  longer exist locally, keeping the bucket in exact sync.
#                  Use with care.
#   --empty        Optional. Removes ALL objects from the bucket instead of
#                  uploading anything. Run this before 'terraform destroy'
#                  or 'aws cloudformation delete-stack' if the bucket isn't
#                  set to auto-delete, since a non-empty bucket can't be
#                  removed. Use with care.

set -euo pipefail

DEFAULT_BUCKET_NAME="bdahiya-ecommerce-static-website"
DEFAULT_LOCAL_FOLDER="./s3-static-website"

usage() {
  cat <<EOF
Usage: ./deploy.sh [bucket-name] [local-folder] [--delete]
       ./deploy.sh [bucket-name] --empty

Uploads local website files to an S3 bucket using 'aws s3 sync'.

Arguments:
  bucket-name    Optional. Name of the target S3 bucket.
                 Defaults to $DEFAULT_BUCKET_NAME
  local-folder   Optional. Local folder to upload.
                 Defaults to $DEFAULT_LOCAL_FOLDER
  --delete       Optional. Also removes files from the bucket that no
                 longer exist locally, keeping the bucket in exact sync.
                 Use with care.
  --empty        Optional. Removes ALL objects from the bucket instead of
                 uploading anything. Use this before 'terraform destroy'
                 or 'aws cloudformation delete-stack' when the bucket
                 isn't set to auto-delete on destroy, since a non-empty
                 bucket can't be removed. Use with care.

Examples:
  ./deploy.sh
  ./deploy.sh $DEFAULT_BUCKET_NAME
  ./deploy.sh $DEFAULT_BUCKET_NAME $DEFAULT_LOCAL_FOLDER
  ./deploy.sh $DEFAULT_BUCKET_NAME $DEFAULT_LOCAL_FOLDER --delete
  ./deploy.sh $DEFAULT_BUCKET_NAME --empty
EOF
}

for arg in "$@"; do
  if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
    usage
    exit 0
  fi
done

EMPTY_MODE="false"
for arg in "$@"; do
  if [[ "$arg" == "--empty" ]]; then
    EMPTY_MODE="true"
  fi
done

BUCKET_NAME="${1:-$DEFAULT_BUCKET_NAME}"
LOCAL_FOLDER="${2:-$DEFAULT_LOCAL_FOLDER}"
DELETE_FLAG=""

if [[ "$BUCKET_NAME" == "--empty" ]]; then
  BUCKET_NAME="$DEFAULT_BUCKET_NAME"
fi
if [[ "$LOCAL_FOLDER" == "--empty" ]]; then
  LOCAL_FOLDER="$DEFAULT_LOCAL_FOLDER"
fi

if [[ "$BUCKET_NAME" == "--delete" ]]; then
  DELETE_FLAG="--delete"
  BUCKET_NAME="$DEFAULT_BUCKET_NAME"
  LOCAL_FOLDER="$DEFAULT_LOCAL_FOLDER"
elif [[ "$LOCAL_FOLDER" == "--delete" ]]; then
  DELETE_FLAG="--delete"
  LOCAL_FOLDER="$DEFAULT_LOCAL_FOLDER"
elif [[ "${3:-}" == "--delete" ]]; then
  DELETE_FLAG="--delete"
fi

if [[ "$BUCKET_NAME" == -* && "$BUCKET_NAME" != "--delete" && "$BUCKET_NAME" != "--empty" ]]; then
  echo "Error: unrecognized option '$BUCKET_NAME'."
  usage
  exit 1
fi

if [[ "$EMPTY_MODE" == "true" ]]; then
  echo "Bucket: s3://$BUCKET_NAME/"
  echo "Mode:   EMPTY (removes ALL objects from this bucket)"
  echo ""
  echo "This is typically run before 'terraform destroy' or"
  echo "'aws cloudformation delete-stack', since a non-empty bucket"
  echo "can't be deleted."
  echo ""
  read -p "This will permanently delete all objects in the bucket. Proceed? [y/N] " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi

  aws s3 rm "s3://$BUCKET_NAME/" --recursive

  echo ""
  echo "Bucket emptied. You can now safely run 'terraform destroy' or"
  echo "'aws cloudformation delete-stack --stack-name <your-stack>'."
  exit 0
fi

if [[ ! -d "$LOCAL_FOLDER" ]]; then
  echo "Error: local folder '$LOCAL_FOLDER' does not exist."
  exit 1
fi

echo "Bucket:       s3://$BUCKET_NAME/"
echo "Local folder: $LOCAL_FOLDER"
if [[ -n "$DELETE_FLAG" ]]; then
  echo "Mode:         sync with delete (bucket will exactly mirror local folder)"
else
  echo "Mode:         sync (no deletions)"
fi
echo ""

read -p "Proceed with upload? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

aws s3 sync "$LOCAL_FOLDER" "s3://$BUCKET_NAME/" $DELETE_FLAG

echo ""
echo "Upload complete."
echo "If static website hosting is enabled, your site should be live at:"
echo "  http://$BUCKET_NAME.s3-website-<your-region>.amazonaws.com"