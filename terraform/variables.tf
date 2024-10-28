variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block"
}
variable "key_name" {
  type        = string
  description = "SSH key name"
}