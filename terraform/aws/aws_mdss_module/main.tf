
resource "aws_security_group" "mongo_db_security_group" {
  count  = var.DEPLOY_MONGO_DB ? 1 : 0
  name = "terraform-${var.MD_CLUSTER_NAME}-cluster-MongoDBSecurityGroup"

  description = "Mongo servers (terraform-managed)"
  vpc_id      = var.VPC_ID

  ingress {
    from_port   = 27017
    to_port     = 27017
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

resource "aws_docdb_cluster_parameter_group" "docdb_pg" {
  count       = var.DEPLOY_MONGO_DB ? 1 : 0
  family      = "docdb3.6"
  name        = "${var.MD_CLUSTER_NAME}-pg"
  description = "docdb for kubernetes cluster parameter group"

  parameter {
    name  = "tls"
    value = var.TLS_MONGO_ENABLED
  }
}

resource "aws_docdb_subnet_group" "docdb_sub" {
  count      = var.DEPLOY_MONGO_DB ? 1 : 0
  name       = "${var.MD_CLUSTER_NAME}-docdb-subnet"
  subnet_ids = var.PRIVATE_SUBNETS

  tags = {
    Name = "My docdb subnet group"
  }
}

resource "aws_docdb_cluster" "docdb" {
  count  = var.DEPLOY_MONGO_DB ? 1 : 0
  cluster_identifier      = "${var.MD_CLUSTER_NAME}-db-cluster"
  engine                  = "docdb"
  engine_version          = "3.6.0"
  master_username         = var.MONGO_USERNAME
  master_password         = var.MONGO_PASSWORD
  db_subnet_group_name    = aws_docdb_subnet_group.docdb_sub[0].name
  skip_final_snapshot     = true
  port                    = 27017
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.docdb_pg[0].id
  vpc_security_group_ids = [aws_security_group.mongo_db_security_group[0].id]
  depends_on = [aws_security_group.mongo_db_security_group[0]]
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.DEPLOY_MONGO_DB ? 1 : 0
  identifier         = "${var.MD_CLUSTER_NAME}-docdb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb[0].id
  instance_class     = "db.r5.large"
}


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
  engine_version     = "3.11.20"
  host_instance_type = "mq.m5.large"
  deployment_mode    = "CLUSTER_MULTI_AZ"
  security_groups    = [aws_security_group.rabbitmq_security_group[0].id]
  subnet_ids         = var.PRIVATE_SUBNETS

  user {
    username = var.MQ_USERNAME
    password = var.MQ_PASSWORD
  }

  depends_on = [aws_security_group.rabbitmq_security_group[0]]
}
