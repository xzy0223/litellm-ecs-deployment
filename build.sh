#!/bin/bash

# build & deploy litellm docker image to ECR
# make sure you have aws cli configured with proper permissions

set -e

AWS_REGION=${1:-"us-east-1"}
AWS_PROFILE=${2:-"default"}
REPO_NAME="litellm-dev"
IMAGE_TAG="latest"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile $AWS_PROFILE --region $AWS_REGION)
REPO_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME"

# login to ecr
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | docker login --username AWS --password-stdin $REPO_URL

# build on linux/amd64 platform ;; check your ecs configuration to selcet platform
docker buildx build --platform linux/amd64 -t $REPO_NAME:$IMAGE_TAG --load .

# tag image
docker tag $REPO_NAME:$IMAGE_TAG $REPO_URL:$IMAGE_TAG

# push image to ecr
docker push $REPO_URL:$IMAGE_TAG

aws ecs update-service --cluster litellm-ecs-cluster --service litellm-service --force-new-deployment --profile $AWS_PROFILE --region $AWS_REGION

echo "repo url: $REPO_URL:$IMAGE_TAG"