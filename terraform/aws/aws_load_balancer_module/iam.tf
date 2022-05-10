# Policy
data "aws_iam_policy_document" "lb_controller" {
  statement {
    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"

      values = [
        "elasticloadbalancing.amazonaws.com"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
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
      "shield:DeleteProtection"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:CreateSecurityGroup"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:CreateTags"
    ]

    resources = [
      "arn:aws:ec2:*:*:security-group/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"

      values = [
        "CreateSecurityGroup"
      ]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]

    resources = [
      "arn:aws:ec2:*:*:security-group/*"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

      values = [
        "true"
      ]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]

    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"

      values = [
        "true"
      ]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"

      values = [
        "false"
      ]
    }

    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }

}

resource "aws_iam_policy" "lb_controller" {
  name        = "${var.MD_CLUSTER_NAME}-alb-ingress"
  path        = "/"
  description = "Policy for alb-ingress service"

  policy = data.aws_iam_policy_document.lb_controller.json
}

# Role
data "aws_iam_policy_document" "lb_controller_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oicd_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.EKS_CLUSTER_OICD_URL, "https://", "")}:sub"

      values = [
        "system:serviceaccount:${var.SERVICE_ACCOUNT_NAMESPACE}:${var.SERVICE_ACCOUNT_NAME}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "lb_controller" {
  name               = "${var.MD_CLUSTER_NAME}-alb-ingress"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume.json
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}