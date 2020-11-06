resource "aws_security_group" "blog_ohr486_net_allow_all" {
  name = "blog-ohr486-net-sg-allow-all"
  description = "blog-ohr486-net-sg-allow-all"
  vpc_id = "${aws_vpc.blog_ohr486_net.id}"
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "blog-ohr486-net-sg-allow-all"
  }
}
