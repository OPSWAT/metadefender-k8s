resource "aws_security_group" "redis_security_group" {
  count  = var.DEPLOY_REDIS ? 1 : 0
  name = "terraform-${var.MD_CLUSTER_NAME}-cluster-RedisSecurityGroup"

  description = "Redis Clusters (terraform-managed)"
  vpc_id      = var.VPC_ID

  ingress {
    from_port   = 6379
    to_port     = 6379
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

resource "aws_elasticache_subnet_group" "redis_subnet" {
  count      = var.DEPLOY_REDIS ? 1 : 0
  name       = "${var.MD_CLUSTER_NAME}-redis-subnet"
  subnet_ids = var.PRIVATE_SUBNETS
}



resource "aws_elasticache_replication_group" "redis_cache" {
  count  = var.DEPLOY_REDIS ? 1 : 0
  replication_group_id       = "${var.MD_CLUSTER_NAME}-redis-cluster"
  description                = "${var.MD_CLUSTER_NAME}-redis-cluster"
  node_type                  = "cache.t2.small"
  port                       = 6379
  parameter_group_name       = "default.redis7.cluster.on"
  automatic_failover_enabled = true
  security_group_ids         = [aws_security_group.redis_security_group[0].id]
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet[0].name

  num_node_groups         = 1
  replicas_per_node_group = 1
}



resource "aws_security_group" "rabbitmq_security_group" {
  count  = var.DEPLOY_RABBITMQ ? 1 : 0
  name = "terraform-${var.MD_CLUSTER_NAME}-cluster-RabbitMQSecurityGroup"

  description = "Rabbit MQ Clusters (terraform-managed)"
  vpc_id      = var.VPC_ID

  ingress {
    from_port   = 5671
    to_port     = 5671
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

resource "aws_mq_broker" "rabbitmq_broker" {
  count  = var.DEPLOY_RABBITMQ ? 1 : 0
  broker_name = "${var.MD_CLUSTER_NAME}-mq-broker"

  engine_type        = "RabbitMQ"
  engine_version     = "3.13"
  host_instance_type = "mq.m5.large"
  deployment_mode    = "CLUSTER_MULTI_AZ"
  security_groups    = [aws_security_group.rabbitmq_security_group[0].id]
  subnet_ids         = var.PRIVATE_SUBNETS
  auto_minor_version_upgrade = true

  user {
    username = var.MQ_USERNAME
    password = var.MQ_PASSWORD
  }

  depends_on = [aws_security_group.rabbitmq_security_group[0]]
}
