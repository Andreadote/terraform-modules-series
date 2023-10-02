resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = {
    Environment = var.enviroment_tag
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Environment = var.enviroment_tag
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_subnet
  map_public_ip_on_launch = false
  availability_zone       = var.azs

  tags = {
    Environment = var.enviroment_tag
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Environment = var.enviroment_tag
  }
}

resource "aws_route_table_association" "rta_public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rtb_public.id
}


resource "aws_security_group" "prod-SG" {
  name   = "prod-SG"
  vpc_id = aws_vpc.vpc.id

  # ssh access from the vpc
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]


  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.enviroment_tag
  }
}

  resource "aws_key_pair" "Demo32" {
  key_name   = "Demo32"
  public_key = var.public_key_path
}


resource "aws_instance" "testinstance" {
  ami                    = var.instance_ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.prod-SG.id]
  key_name               = aws_key_pair.Demo32.key_name
  ebs_optimized          = true
  monitoring             = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }


  tags = {
    Environment = var.enviroment_tag
  }

}