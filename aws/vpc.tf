resource "aws_vpc" "blog_ohr486_net" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags {
    Name     = "blog-ohr486-net-vpc"
    Resource = "blog-ohr486-net"
  }
}

resource "aws_subnet" "blog_ohr486_net" {
  vpc_id = "${aws_vpc.blog_ohr486_net.id}"
  availability_zone = "ap-northeast-1a"
  cidr_block = "10.30.0.0/20"
  map_public_ip_on_launch = true
  tags {
    Name     = "blog-ohr486-net-vpc"
    Resource = "blog-ohr486-net"
  }
}

resource "aws_internet_gateway" "blog_ohr486_net" {
  vpc_id = "${aws_vpc.blog_ohr486_net.id}"
  tags {
    Name     = "blog-ohr486-net-igw"
    Resource = "blog-ohr486-net"
  }
}

resource "aws_route_table" "blog_ohr486_net" {
  vpc_id = "${aws_vpc.blog_ohr486_net.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.blog_ohr486_net.id}"
  }
  lifecycle {
    ignore_changes = ["route"]
  }
  tags {
    Name     = "blog-ohr486-net-routing-table"
    Resource = "blog-ohr486-net"
  }
}

resource "aws_route_table_association" "blog_ohr486_net" {
  subnet_id      = "${aws_subnet.blog_ohr486_net.id}"
  route_table_id = "${aws_route_table.blog_ohr486_net.id}"
}
