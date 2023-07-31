provider "aws" {
  region = "ap-northeast-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "blog-ohr486-net-terraform" # SET YOUR PROFILE
}
