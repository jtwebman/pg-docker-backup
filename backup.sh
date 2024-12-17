#!/bin/sh
set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Fail the pipeline if any command in it fails

# Function to read secret files to support docker swarm (only passes secrets by file)
get_value_or_file() {
  ENV_VAR="$1"
  if [ -f "$ENV_VAR" ]; then
    VALUE=$(cat "$ENV_VAR")
  else
    VALUE="$ENV_VAR"
  fi
  echo "$VALUE"
}

# Define Backblaze credentials and configuration
ACCESS_KEY_ID=$(get_value_or_file "$S3_APPLICATION_KEY_ID")
SECRET_ACCESS_KEY=$(get_value_or_file "$S3_SECRET_ACCESS_KEY")
BUCKET_NAME="${S3_BUCKET_NAME}"
OBJECT_KEY_PREFIX=${OBJECT_KEY_PREFIX:-db-backup-}  
REGION="${S3_REGION}"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD=$(get_value_or_file "$DB_PASSWORD")
COMPRESSOR_CMD="${COMPRESSOR_CMD:-gzip}"
OBJECT_KEY_SUFFIX="${OBJECT_KEY_SUFFIX:-.sql.gz}"
OBJECT_KEY="${OBJECT_KEY_PREFIX}$(date +%Y%m%d-%H%M%S)${OBJECT_KEY_SUFFIX}"

if [ -n "$DB_PASSWORD" ]; then
  export PGPASSWORD="${DB_PASSWORD}"
fi

# Check if EXPECTED_SIZE has a value
if [ -n "$S3_API_URL" ]; then
  S3_API_URL_CMD=" --endpoint-url $S3_API_URL"
else
  S3_API_URL_CMD=" "
fi

# Check if EXPECTED_SIZE has a value
if [ -n "$EXPECTED_SIZE" ]; then
  EXPECTED_SIZE_CMD=" --expected-size $EXPECTED_SIZE"
else
  EXPECTED_SIZE_CMD=" "
fi

# Configure AWS CLI to use Backblaze as the S3 endpoint
aws configure set aws_access_key_id "${ACCESS_KEY_ID}"
aws configure set aws_secret_access_key "${SECRET_ACCESS_KEY}"
aws configure set region "${REGION}"

# Run pg_dumpall, compress it, and upload to any S3 compatible api that can use `aws s3 cp`
pg_dumpall -c -U "${DB_USER}" -h "${DB_HOST}" -l "${DB_NAME}" -p ${DB_PORT} -w | ${COMPRESSOR_CMD} | \
aws s3 cp ${S3_API_URL_CMD}${EXPECTED_SIZE_CMD} - "s3://${BUCKET_NAME}/${OBJECT_KEY}"

# Check if the upload was successful
if [ $? -eq 0 ]; then
  echo "Backup uploaded successfully to Backblaze: ${BUCKET_NAME}/${OBJECT_KEY}"
else
  echo "Failed to upload the backup to Backblaze."
  exit 1
fi