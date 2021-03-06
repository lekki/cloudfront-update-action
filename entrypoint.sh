#!/bin/sh

set -e

if [ -z "$AWS_CF_DISTRIBUTION_ID" ]; then
  echo "AWS_CF_DISTRIBUTION_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi

# Default to us-east-1 if AWS_REGION not set.
if [ -z "$AWS_REGION" ]; then
  AWS_REGION="us-east-1"
fi

if [ -z "$NEW_VALUE" ]; then
  echo "$NEW_VALUE is not set. Quitting."
  exit 1
fi

aws configure --profile cloudfront-update-action <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
json
EOF


sh -c "aws cloudfront get-distribution-config --id ${AWS_CF_DISTRIBUTION_ID} --profile cloudfront-update-action > distr_config_${GITHUB_SHA}.json"

etag=`cat distr_config_${GITHUB_SHA}.json | jq -r ".ETag"`

query='.DistributionConfig | .Origins.Items[0].OriginPath=$new_path'
sh -c "jq --arg new_path \"/$NEW_VALUE\" '$query' distr_config_${GITHUB_SHA}.json > ${GITHUB_SHA}.json"

sh -c "aws cloudfront update-distribution --distribution-config file://${GITHUB_SHA}.json --id ${AWS_CF_DISTRIBUTION_ID} --if-match ${etag}"
sh -c "rm ${GITHUB_SHA}.json distr_config_${GITHUB_SHA}.json"


# Clear out credentials after we're done.
# We need to re-run `aws configure` with bogus input instead of
# deleting ~/.aws in case there are other credentials living there.
# https://forums.aws.amazon.com/thread.jspa?threadID=148833
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
null
null
null
text
EOF