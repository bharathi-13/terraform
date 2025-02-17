provider "aws" {}

variable "vpc_cidr" {}
variable "sn_cidr" {}
variable "ssh_key_pub" {}

resource "aws_vpc" "tf_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "tf_vpc"
  }
}

resource "aws_subnet" "tf_sn" {
  count = 2
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = var.sn_cidr[count.index]
  availability_zone = "ap-south-1a"
}

resource "aws_internet_gateway" "tf_gw" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "tf_ig"
  }
}

resource "aws_route_table" "tf_rt" {
  vpc_id = aws_vpc.tf_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_gw.id
  }
  tags = {
    Name = "tf_rt"
  }
}

resource "aws_route_table_association" "tf_a" {
  subnet_id      = aws_subnet.tf_sn[1].id
  route_table_id = aws_route_table.tf_rt.id
}

resource "aws_security_group" "tf_sg" {
  vpc_id = aws_vpc.tf_vpc.id
  ingress {
    from_port      = 0
    to_port        = 0
    protocol       = "icmp"
    cidr_blocks    = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "tf_sg"
  }
}

resource "aws_key_pair" "tf_key" {
  key_name   = "tf_key"
  public_key = var.ssh_key_pub
}

data "aws_ami" "amzn2_img" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20241113.1-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "tf_instance_1" {
  ami           = data.aws_ami.amzn2_img.id
  instance_type = "t3.micro"
  key_name = "tf_key"
  subnet_id = aws_subnet.tf_sn[1].id
  security_groups = [aws_security_group.tf_sg.id]
  availability_zone = "ap-south-1a"

  tags = {
    Name = "tf_instance_1"
  }
}