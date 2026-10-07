variable "aws_region" {
  description = "Região AWS padrão"
  type        = string
  default     = "us-east-1"
}

variable "localstack_url" {
  description = "URL do endpoint do LocalStack"
  type        = string
  default     = "http://localhost:4566"
}

variable "environment" {
  description = "Ambiente de implantação"
  type        = string
  default     = "dev"
}
