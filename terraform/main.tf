# Bucket S3 para armazenar relatórios e exportações (Suportado no Community)
resource "aws_s3_bucket" "artifacts" {
  bucket        = "devops-activity-artifacts-${var.environment}"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = "DevOps-Activity"
  }
}

# Fila SQS para simulação de processamento assíncrono (Suportado no Community)
resource "aws_sqs_queue" "flash_sales_queue" {
  name                      = "flash-sales-orders-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = {
    Environment = var.environment
    Project     = "DevOps-Activity"
  }
}
