terraform {
  backend "s3" {
    bucket         = "blog.ohr486.net.terraform"
    key            = "blog-ohr486-net-tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "tfstate"
    shared_credentials_file = "credentials"
  }
}
