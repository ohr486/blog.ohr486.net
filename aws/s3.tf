resource "aws_s3_bucket" "blog_ohr486_net" {
  bucket = "blog.ohr486.net"
  acl = "public-read"

  versioning {
    enabled = true
  }

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "blog_ohr486_net" {
  bucket = aws_s3_bucket.blog_ohr486_net.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "BLOG_OHR486_NET_POLICY"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::blog.ohr486.net/*"
        ]
      }
    ]
  })
}

locals {
  s3_origin_id_blog_ohr486_net = "s3_origin_id_blog_ohr486_net"
}
