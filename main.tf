
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

#Define aws as the provider
provider "aws"{
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "vpc"{
  cidr_block = "10.0.0.0/18"
  tags = { Name = "HW4_vpc"}
}

# Create a internet Gateway
resource "aws_internet_gateway" "ig"{
  vpc_id = aws_vpc.vpc.id  //refer to created vpc
  tags = { Name = "my_igw"}
}

# Create Public Subnets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "public_subnets"{
  vpc_id = aws_vpc.vpc.id
  count = length(var.public_subnet_cidrs)  // gets count of public_subnets 
  cidr_block = element(var.public_subnet_cidrs, count.index) // assignes based on index
  availability_zone = element(var.availabilty_zones, count.index) // Assign AZ
  
  tags = {
    Name = "Public Subnet: ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets"{
  vpc_id = aws_vpc.vpc.id
  count = length(var.private_subnet_cidrs)  // gets count of public_subnets 
  cidr_block = element(var.private_subnet_cidrs, count.index) // assignes based on idex
  availability_zone = element(var.availabilty_zones, count.index) // Assign AZ
    
  tags = {
    Name = "Private Subnet: ${count.index + 1}"
  }
}


# Create Route Table
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "rt"{
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"  // public ip
    gateway_id = aws_internet_gateway.ig.id  //refer to created internet gateway
  }
  
  tags = { Name = "my_rt"}
}

# Associate public subnets to allow public access
resource "aws_route_table_association" "rt_association-subnet"{
  count = length(var.public_subnet_cidrs)
  subnet_id  = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id  = aws_route_table.rt.id
}

# Create Security group to allow port 80
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
  
  # Allow incoming requests on port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow incoming requests from port 22 from your workstation
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow incoming requests port 3306
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Instances in Public subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "app_server" {
  ami           = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  count = length(var.public_subnet_cidrs)
  subnet_id  = element(aws_subnet.public_subnets[*].id, count.index)
  associate_public_ip_address = true
  
  tags = {
    Name = element(var.instance_name, count.index)
  }
}

# Create a RDS Database Instances
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  
  
  vpc_security_group_ids = [aws_security_group.sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.id
}

resource "aws_db_subnet_group" "rds_subnet_group"{
  subnet_ids  = [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id]

  tags = { Name = "RDS Subnet Group" }
}