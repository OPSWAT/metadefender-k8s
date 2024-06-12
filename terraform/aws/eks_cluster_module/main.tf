## NETWORKING
resource "aws_vpc" "vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "terraform-${var.MD_CLUSTER_NAME}-cluster/VPC"
    Environment = terraform.workspace
  }
}

data "aws_availability_zones" "all" {}

resource "aws_subnet" "pub_subnet" {
  count = min(3,length(data.aws_availability_zones.all.names))

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 3, count.index)
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                           = "terraform-${var.MD_CLUSTER_NAME}-cluster/SubnetPublic${data.aws_availability_zones.all.names[count.index]}"
    "kubernetes.io/cluster/${var.MD_CLUSTER_NAME}" = "shared"
    "kubernetes.io/role/elb"                       = 1
    Environment                                    = terraform.workspace
  }
}

resource "aws_subnet" "priv_subnet" {
  count = min(3,length(data.aws_availability_zones.all.names))

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 3, count.index + min(3,length(data.aws_availability_zones.all.names)))
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                                           = "terraform-${var.MD_CLUSTER_NAME}-cluster/SubnetPrivate${data.aws_availability_zones.all.names[count.index]}"
    "kubernetes.io/cluster/${var.MD_CLUSTER_NAME}" = "shared"
    "kubernetes.io/role/internal-elb"              = 1
    Environment                                    = terraform.workspace
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "terraform-${var.MD_CLUSTER_NAME}-cluster/InternetGateway"
  }
}

resource "aws_eip" "nat_eip" {
  tags = {
    Name = "terraform-${var.MD_CLUSTER_NAME}-cluster/NATIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.pub_subnet[0].id
  tags = {
    Name = "terraform-${var.MD_CLUSTER_NAME}-cluster/NATGateway"
  }
  depends_on = [
    aws_internet_gateway.ig
  ]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
  tags = {
    Name = "terraform-${var.MD_CLUSTER_NAME}-cluster/PublicRouteTable"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "terraform-${var.MD_CLUSTER_NAME}-cluster/PrivateRouteTable"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.all.names)
  subnet_id      = element(aws_subnet.pub_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(data.aws_availability_zones.all.names)
  subnet_id      = element(aws_subnet.priv_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

data "aws_security_groups" "eks_security_group" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc.id]
  }
  filter {
    name   = "description"
    values = ["EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads."]
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

resource "aws_security_group" "ClusterSharedNodeSecurityGroup" {
  name        = "terraform-${var.MD_CLUSTER_NAME}-cluster-ClusterSharedNodeSecurityGroup"
  description = "Communication between all nodes in the cluster"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Allow managed and unmanaged nodes to communicate with each other (all ports)"
    protocol        = "all"
    from_port       = 0
    to_port         = 0
    security_groups = [data.aws_security_groups.eks_security_group.ids[0]]
  }

  ingress {
    description = "Allow nodes to communicate with each other (all ports)"
    protocol    = "all"
    from_port   = 0
    to_port     = 0
    self        = true
  }

  egress {
    protocol    = "all"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ControlPlaneSecurityGroup" {
  name        = "terraform-${var.MD_CLUSTER_NAME}-cluster-ControlPlaneSecurityGroup"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = aws_vpc.vpc.id

  egress {
    protocol    = "all"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "IngressNodeToDefaultClusterSG" {
  security_group_id        = data.aws_security_groups.eks_security_group.ids[0]
  type                     = "ingress"
  protocol                 = "all"
  to_port                  = 0
  from_port                = 0
  source_security_group_id = aws_security_group.ClusterSharedNodeSecurityGroup.id
  description              = "Allow unmanaged nodes to communicate with control plane (all ports)"
}

resource "aws_security_group" "NodeGroupRemoteAccessSecurityGroup" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  name        = "terraform-${var.MD_CLUSTER_NAME}-nodegroup-remoteAccess"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.vpc.id

  # ingress {
  #   description      = "Allow SSH access to managed worker nodes in group terraform-${var.MD_CLUSTER_NAME}-nodegroup"
  #   protocol         = "tcp"
  #   from_port        = 22
  #   to_port          = 22
  #   ipv6_cidr_blocks = ["::/0"]
  # }

  ingress {
    description = "Allow SSH access to managed worker nodes in group terraform-${var.MD_CLUSTER_NAME}-nodegroup"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [aws_vpc.vpc.cidr_block, "10.0.0.0/8", "172.16.0.0/12",]
  }

  egress {
    protocol    = "all"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## ACCESS MANAGEMENT

resource "aws_iam_role" "eks_cluster" {
  name = "terraform-${var.MD_CLUSTER_NAME}-cluster-ServiceRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "PolicyELBPermissions" {
  name = "terraform-${var.MD_CLUSTER_NAME}-cluster-PolicyELBPermissions"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "PolicyCloudWatchMetrics" {
  name = "terraform-${var.MD_CLUSTER_NAME}-cluster-PolicyCloudWatchMetrics"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "cloudwatch:PutMetricData"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "PolicyELBPermissions" {
  policy_arn = aws_iam_policy.PolicyELBPermissions.arn
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "PolicyCloudWatchMetrics" {
  policy_arn = aws_iam_policy.PolicyCloudWatchMetrics.arn
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  count = var.DEPLOY_FARGATE_NODES ? 1 : 0
  name  = "terraform-${var.MD_CLUSTER_NAME}-cluster-FargatePodExecutionRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks-fargate-pods.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  count      = var.DEPLOY_FARGATE_NODES ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role[0].name
}

resource "aws_iam_role" "eks_nodes_role" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  name = "terraform-${var.MD_CLUSTER_NAME}-nodegroup-NodeInstanceRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "PolicyAWSLoadBalancerController" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  name = "terraform-${var.MD_CLUSTER_NAME}-nodegroup-PolicyAWSLoadBalancerController"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : "CreateSecurityGroup"
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        },
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Effect" : "Allow"
      },
      {
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        },
        "Action" : [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Effect" : "Allow"
      },
      {
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        },
        "Action" : [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        },
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:DescribeVpcPeeringConnections",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes_role[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes_role[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_nodes_role[0].name
}

resource "aws_iam_role_policy_attachment" "PolicyAWSLoadBalancerController" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  policy_arn = aws_iam_policy.PolicyAWSLoadBalancerController[0].arn
  role       = aws_iam_role.eks_nodes_role[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes_role[0].name
}

resource "tls_private_key" "private_key" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  key_name   = var.MD_CLUSTER_NAME
  public_key = tls_private_key.private_key[0].public_key_openssh
}

## CLUSTER CREATION

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.MD_CLUSTER_NAME
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = concat(aws_subnet.pub_subnet.*.id, aws_subnet.priv_subnet.*.id)
    security_group_ids = [aws_security_group.ControlPlaneSecurityGroup.id]
  }

  tags = {
    Name = "terraform-${var.MD_CLUSTER_NAME}-cluster/ControlPlane"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.PolicyELBPermissions,
    aws_iam_role_policy_attachment.PolicyCloudWatchMetrics
  ]
}

resource "aws_eks_fargate_profile" "fargate_profile" {
  count = var.DEPLOY_FARGATE_NODES ? 1 : 0

  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = var.PERSISTENT_DEPLOYMENT ? "fp-${var.MD_CLUSTER_NAME}" : "fp-default"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role[0].arn
  subnet_ids             = aws_subnet.priv_subnet.*.id

  selector {
    namespace = "default"
    labels = {
      aws-type = "fargate"
    }
  }

  dynamic "selector" {
    for_each = var.PERSISTENT_DEPLOYMENT ? [] : [{}]
    content {
      namespace = "kube-system"
    }
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

data "aws_eks_cluster_auth" "eks_cluster_auth" {
  count = var.PERSISTENT_DEPLOYMENT || !var.DEPLOY_FARGATE_NODES ? 0 : 1

  name = aws_eks_cluster.eks_cluster.name
}

locals {
  kubeconfig = var.PERSISTENT_DEPLOYMENT || !var.DEPLOY_FARGATE_NODES ? "" : <<-EOF
    apiVersion: v1
    kind: Config
    current-context: terraform
    clusters:
    - name: ${aws_eks_cluster.eks_cluster.name}
      cluster:
        certificate-authority-data: ${aws_eks_cluster.eks_cluster.certificate_authority.0.data}
        server: ${aws_eks_cluster.eks_cluster.endpoint}
    contexts:
    - name: terraform
      context:
        cluster: ${aws_eks_cluster.eks_cluster.name}
        user: terraform
    users:
    - name: terraform
      user:
        token: ${data.aws_eks_cluster_auth.eks_cluster_auth[0].token}
  EOF
}

resource "local_file" "kubeconfig" {
  count = var.PERSISTENT_DEPLOYMENT || !var.DEPLOY_FARGATE_NODES ? 0 : 1

  filename = "${path.module}/.kubeconfig"
  content  = local.kubeconfig
}

// Hack to make CoreDNS run on Fargate nodes
resource "null_resource" "update_coredns_annotations" {
  count = var.PERSISTENT_DEPLOYMENT || !var.DEPLOY_FARGATE_NODES ? 0 : 1

  provisioner "local-exec" {
    interpreter = ["${local.os == "Linux" ? "/bin/bash" : "PowerShell"}", "${local.os == "Linux" ? "-c" : "-Command"}"]
    environment = {
      KUBECONFIG = base64encode(local_file.kubeconfig[0].content)
    }
    command = <<-EOF
      kubectl \
        -n kube-system \
        --kubeconfig <(echo $KUBECONFIG | base64 --decode) \
        patch deployment coredns \
        --type json \
        -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
    EOF
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_eks_fargate_profile.fargate_profile
  ]
}

resource "aws_launch_template" "launch_template" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  name = "terraform-${var.MD_CLUSTER_NAME}-nodegroup"

  vpc_security_group_ids = [data.aws_security_groups.eks_security_group.ids[0], aws_security_group.NodeGroupRemoteAccessSecurityGroup[0].id]
  key_name               = aws_key_pair.key_pair[0].key_name

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 80
      volume_type = "gp3"
      throughput  = 125
      iops        = 3000
    }
  }
}

resource "aws_eks_node_group" "node_group" {
  count = var.PERSISTENT_DEPLOYMENT ? 1 : 0

  cluster_name    = var.MD_CLUSTER_NAME
  node_group_name = "terraform-${var.MD_CLUSTER_NAME}-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodes_role[0].arn
  subnet_ids      = aws_subnet.pub_subnet.*.id
  instance_types  = ["c5.2xlarge"]
  labels = {
    type = "ec2-db-node"
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  launch_template {
    id      = aws_launch_template.launch_template[0].id
    version = aws_launch_template.launch_template[0].latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.PolicyAWSLoadBalancerController,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_eks_cluster.eks_cluster
  ]
}


### Group Subnet for other resources

resource "aws_db_subnet_group" "private_subnet_group" {
  name       = "${var.MD_CLUSTER_NAME}-private-subnet-group"
  subnet_ids = [for subnet in aws_subnet.priv_subnet : subnet.id]
}