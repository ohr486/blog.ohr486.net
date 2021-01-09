terraform {
  backend "s3" {
    bucket                  = "ohr486.terraform"          # SET YOUR BUCKET
    key                     = "blog-ohr486-net.tfstate"   # SET YOUR KEY
    region                  = "ap-northeast-1"
    dynamodb_table          = "tfstate"                   # SET YOUR DDB TABLE
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "blog-ohr486-net-terraform" # SET YOUR PROFILEt
  }
}
