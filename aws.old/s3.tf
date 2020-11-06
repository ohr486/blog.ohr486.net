# tf backend bucket
resource "aws_s3_bucket" "s3_ohr486_terraform" {
  bucket = "blog.ohr486.net.terraform"
  acl    = "private"
}
