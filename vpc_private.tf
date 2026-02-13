# Private Subnets for ECS Tasks, RDS, and Redis
# Creates private subnets in 3 AZs with NAT Gateway for outbound connectivity

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway (already exists with default VPC, but we reference it)
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [aws_default_vpc.ecs-vpc.id]
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "litellm-nat-eip"
  }
}

# NAT Gateway (deployed in public subnet for internet access)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_default_subnet.ecs_az1.id  # Use public subnet

  tags = {
    Name = "litellm-nat-gateway"
  }

  depends_on = [data.aws_internet_gateway.default]
}

# Private Subnets (no direct internet access)
resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_default_vpc.ecs-vpc.id
  cidr_block              = "172.31.112.0/20"  # Non-overlapping CIDR range
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "litellm-private-subnet-1a"
    Type = "private"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_default_vpc.ecs-vpc.id
  cidr_block              = "172.31.128.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "litellm-private-subnet-1b"
    Type = "private"
  }
}

resource "aws_subnet" "private_az3" {
  vpc_id                  = aws_default_vpc.ecs-vpc.id
  cidr_block              = "172.31.144.0/20"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "litellm-private-subnet-1c"
    Type = "private"
  }
}

# Route table for private subnets (routes through NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_default_vpc.ecs-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "litellm-private-rt"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az3" {
  subnet_id      = aws_subnet.private_az3.id
  route_table_id = aws_route_table.private.id
}

# Outputs
output "nat_gateway_ip" {
  value       = aws_eip.nat.public_ip
  description = "Public IP of NAT Gateway (all private subnet egress traffic uses this IP)"
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id,
    aws_subnet.private_az3.id
  ]
  description = "Private subnet IDs for ECS tasks"
}
