#!/bin/bash
set -e

echo "==================================="
echo "LiteLLM ECS Deployment Cleanup"
echo "==================================="
echo ""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REGION="us-east-1"
ECR_REPO_NAME="litellm-dev"

echo -e "${YELLOW}Step 1: Cleaning ECR images...${NC}"
# Delete all images from ECR repository
IMAGE_IDS=$(aws ecr list-images \
  --repository-name ${ECR_REPO_NAME} \
  --region ${REGION} \
  --query 'imageIds[*]' \
  --output json 2>/dev/null || echo "[]")

if [ "$IMAGE_IDS" != "[]" ] && [ ! -z "$IMAGE_IDS" ]; then
  echo "  Found images in ECR, deleting..."
  aws ecr batch-delete-image \
    --repository-name ${ECR_REPO_NAME} \
    --region ${REGION} \
    --image-ids "$IMAGE_IDS" > /dev/null 2>&1 || true
  echo -e "  ${GREEN}✓ ECR images deleted${NC}"
else
  echo -e "  ${GREEN}✓ No images to delete${NC}"
fi

echo ""
echo -e "${YELLOW}Step 2: Running Terraform destroy...${NC}"
terraform destroy -auto-approve

echo ""
echo -e "${YELLOW}Step 3: Cleaning Terraform intermediate files...${NC}"
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl tfplan 2>/dev/null || true
echo -e "  ${GREEN}✓ Terraform files cleaned${NC}"

echo ""
echo -e "${GREEN}==================================="
echo "Cleanup completed successfully!"
echo "===================================${NC}"
