#!/bin/bash

# build & deploy litellm docker image to ECR
# Usage:
#   ./build.sh                          # use environment credentials (EC2 role, env vars)
#   ./build.sh us-west-2                # specify region
#   ./build.sh us-west-2 my-profile     # specify region and AWS CLI profile

set -e

AWS_REGION=${1:-"us-east-1"}
AWS_PROFILE=${2:-""}
REPO_NAME="litellm-dev"
IMAGE_TAG="latest"

# Build --profile flag only if profile is specified
PROFILE_FLAG=""
if [ -n "$AWS_PROFILE" ]; then
  PROFILE_FLAG="--profile $AWS_PROFILE"
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text $PROFILE_FLAG --region $AWS_REGION)
REPO_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME"

# login to ecr
aws ecr get-login-password --region $AWS_REGION $PROFILE_FLAG | docker login --username AWS --password-stdin $REPO_URL

# build on linux/amd64 platform
docker build --platform linux/amd64 -t $REPO_NAME:$IMAGE_TAG .

# tag image
docker tag $REPO_NAME:$IMAGE_TAG $REPO_URL:$IMAGE_TAG

# push image to ecr
docker push $REPO_URL:$IMAGE_TAG

aws ecs update-service --cluster litellm-ecs-cluster --service litellm-service --force-new-deployment $PROFILE_FLAG --region $AWS_REGION

echo "repo url: $REPO_URL:$IMAGE_TAG"
