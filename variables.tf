variable "public_subnet_cidrs" {
  type = list(string)
  description = "Public Subnet CIDR values"
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  description = "Private Subnet CIDR values"
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availabilty_zones" {
  type = list(string)
  description = "Availablity Zones to use"
  default = ["us-east-1a", "us-east-1b"]
}

variable "instance_name" {
  type = list(string)
  description = "Value of the Name tag for the EC2 instance"
  default = ["instance1_name", "instance2_name"]
}