resource "aws_cloudfront_distribution" "blog_ohr486_net" {
  origin {
    domain_name = aws_s3_bucket.blog_ohr486_net.bucket_regional_domain_name
    origin_id = local.s3_origin_id_blog_ohr486_net
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.blog_ohr486_net_identity.cloudfront_access_identity_path
    }
  }

  enabled = true
  default_root_object = "index.html"
  wait_for_deployment = true

  aliases             = ["blog.ohr486.net"]

  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:800832305859:certificate/ab05b06a-58f8-490d-8987-744f2c9998bc"
    cloudfront_default_certificate = true
    ssl_support_method             = "sni-only"
  }

  custom_error_response {
    error_code = "404"
    response_code = "200"
    response_page_path = "/404.html"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id_blog_ohr486_net
    compress         = true
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "blog_ohr486_net_identity" {
  comment = "access-identity-blog.ohr486.net.s3.amazonaws.com"
}
