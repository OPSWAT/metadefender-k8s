output "postgres_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}
output "postgres_username" {
  value = aws_db_instance.postgres_db.username
}