resource "aws_security_group" "postgres_db_security_group" {
  name = "terraform-${var.MD_CLUSTER_NAME}-cluster-PostgreSQLSecurityGroup"

  description = "RDS postgres servers (terraform-managed)"
  vpc_id      = var.VPC_ID

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.VPC_CIDR]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres_db" {
  allocated_storage      = 100
  db_subnet_group_name   = var.SUBNET_GROUP_ID
  engine                 = "postgres"
  engine_version         = "14.8"
  identifier             = "${var.MD_CLUSTER_NAME}-postgres-db"
  instance_class         = "db.r6g.xlarge"
  multi_az               = false
  password               = var.POSTGRES_PASSWORD
  port                   = 5432
  publicly_accessible    = false
  storage_encrypted      = true
  storage_type           = "gp2"
  username               = var.POSTGRES_USERNAME
  vpc_security_group_ids = [aws_security_group.postgres_db_security_group.id]
  skip_final_snapshot    = true
}