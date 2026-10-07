
output "s3_bucket_name" {
  description = "Nome do Bucket S3 criado"
  value       = aws_s3_bucket.artifacts.id
}

output "sqs_queue_url" {
  description = "URL da fila SQS criada"
  value       = aws_sqs_queue.flash_sales_queue.id
}
