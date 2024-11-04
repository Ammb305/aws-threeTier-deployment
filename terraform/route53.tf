# Create the Route 53 Hosted Zone for learningdevops.site
resource "aws_route53_zone" "main" {
  name = "learningdevops.site"

  tags = {
    Name = "learningdevops.site"
  }
}

# # Request an ACM certificate with DNS validation
# resource "aws_acm_certificate" "cert" {
#   domain_name       = "learningdevops.site"
#   validation_method = "DNS"

#   tags = {
#     Name = "learningdevops.site"
#   }
# }

# # Create Route 53 records for ACM DNS validation in the hosted zone created above
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.zone_id  # Refers to the hosted zone created above
# }

# # ACM Certificate Validation resource to complete validation using the DNS records
# resource "aws_acm_certificate_validation" "cert_validation" {
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }
