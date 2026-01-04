###VPC Networking

resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = var.enable_host
  enable_dns_support   = var.enable_support

  tags = {
    Name = "Main-VPC"
  }
}



resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "IGW"
  }

  depends_on = [aws_vpc.eks_vpc]
}

resource "aws_subnet" "public-subnet-2a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "Public-subnet-2a"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


resource "aws_subnet" "public-subnet-2b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "Public-subnet-2b"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}



resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
  Name = "public-rt" }

  depends_on = [aws_vpc.eks_vpc, aws_internet_gateway.igw]
}



resource "aws_route_table_association" "pub-route-association-2a" {

  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet-2a.id

}

resource "aws_route_table_association" "pub-route-association-2b" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet-2b.id
}



resource "aws_subnet" "private-subnet-2a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "Private-subnet-2a"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private-subnet-2b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "Private-subnet-2b"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


resource "aws_eip" "ngw-eip" {
  domain = "vpc"

  tags = {
    Name = "eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public-subnet-2b.id
  allocation_id = aws_eip.ngw-eip.id

  tags = {
    Name = "igw-nat"
  }

  depends_on = [aws_internet_gateway.igw, aws_eip.ngw-eip]
}



resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "private-rt"

  }

  depends_on = [aws_nat_gateway.ngw]

}

resource "aws_route_table_association" "private-route-association-2a" {

  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-subnet-2a.id


}

resource "aws_route_table_association" "private-route-association-2b" {

  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-subnet-2b.id

}