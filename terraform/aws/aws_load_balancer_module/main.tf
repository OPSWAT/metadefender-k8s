resource "aws_security_group" "load_balancer_security_group" {
  name        = "terraform-${var.MD_CLUSTER_NAME}-cluster-LoadBalancerSecurityGroup"
  description = "SecurityGroup for LoadBalancer"
  vpc_id      = var.VPC_ID

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "all"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "shared_backend_load_balancer_security_group" {
  name        = "terraform-${var.MD_CLUSTER_NAME}-cluster-SharedBackendLoadBalancerSecurityGroup"
  description = "Shared Backend SecurityGroup for LoadBalancer"
  vpc_id      = var.VPC_ID

  egress {
    protocol    = "all"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_security_groups" "eks_security_group" {
  filter {
    name   = "vpc-id"
    values = [var.VPC_ID]
  }
  filter {
    name   = "description"
    values = ["EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads."]
  }
}

resource "aws_security_group_rule" "target_group_binding_security_group_rule" {
  security_group_id        = data.aws_security_groups.eks_security_group.ids[0]
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_security_group.shared_backend_load_balancer_security_group.id
  description              = "Allow target groups to bind with pods"
}

resource "aws_lb" "mdss_load_balancer" {
  count = var.DEPLOY_MDSS_INGRESS ? 1 : 0

  name               = "${var.MD_CLUSTER_NAME}-mdss-lb"
  internal           = var.EXTERNAL_ACCESS ? false : true
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.load_balancer_security_group.id,
    aws_security_group.shared_backend_load_balancer_security_group.id
  ]
  subnets = var.EXTERNAL_ACCESS ? var.PUBLIC_SUBNETS : var.PRIVATE_SUBNETS
}

resource "aws_lb" "mdcore_load_balancer" {
  count = var.DEPLOY_MDCORE_INGRESS ? 1 : 0

  name               = "${var.MD_CLUSTER_NAME}-mdcore-lb"
  internal           = var.EXTERNAL_ACCESS ? false : true
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.load_balancer_security_group.id,
    aws_security_group.shared_backend_load_balancer_security_group.id
  ]
  subnets = var.EXTERNAL_ACCESS ? var.PUBLIC_SUBNETS : var.PRIVATE_SUBNETS
}

resource "aws_lb_target_group" "webclient_target_group" {
  count = var.DEPLOY_MDSS_INGRESS ? 1 : 0

  name        = "${var.MD_CLUSTER_NAME}-wbcl-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.VPC_ID

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
  }
}

resource "aws_lb_target_group" "systemchecks_target_group" {
  count = var.DEPLOY_MDSS_INGRESS ? 1 : 0

  name        = "${var.MD_CLUSTER_NAME}-sc-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.VPC_ID

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
  }
}

resource "aws_lb_target_group" "mdcore_target_group" {
  count = var.DEPLOY_MDCORE_INGRESS ? 1 : 0

  name        = "${var.MD_CLUSTER_NAME}-mdc-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.VPC_ID

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
  }
}

resource "aws_lb_listener" "mdss_lb_listener" {
  count = var.DEPLOY_MDSS_INGRESS ? 1 : 0

  load_balancer_arn = aws_lb.mdss_load_balancer.0.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener" "mdcore_lb_listener" {
  count = var.DEPLOY_MDCORE_INGRESS ? 1 : 0

  load_balancer_arn = aws_lb.mdcore_load_balancer.0.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "webclient_rule" {
  count = var.DEPLOY_MDSS_INGRESS ? 1 : 0

  listener_arn = aws_lb_listener.mdss_lb_listener.0.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webclient_target_group.0.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_listener_rule" "systemchecks_rule" {
  count = var.DEPLOY_MDSS_INGRESS ? 1 : 0

  listener_arn = aws_lb_listener.mdss_lb_listener.0.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.systemchecks_target_group.0.arn
  }

  condition {
    path_pattern {
      values = ["/status", "/status*"]
    }
  }
}

resource "aws_lb_listener_rule" "mdcore_rule" {
  count = var.DEPLOY_MDCORE_INGRESS ? 1 : 0

  listener_arn = aws_lb_listener.mdcore_lb_listener.0.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mdcore_target_group.0.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

data "tls_certificate" "certificate" {
  url = var.EKS_CLUSTER_OICD_URL
}

resource "aws_iam_openid_connect_provider" "oicd_provider" {
  url = var.EKS_CLUSTER_OICD_URL

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.certificate.certificates.0.sha1_fingerprint
  ]
}