output "load_balancer_service_account_name" {
  value = var.SERVICE_ACCOUNT_NAME
}

output "load_balancer_service_account_role_arn" {
  value = aws_iam_role.lb_controller.arn
}

output "webclient_target_group_arn" {
  value = var.DEPLOY_MDSS_INGRESS ? aws_lb_target_group.webclient_target_group.0.arn : null
}

output "systemchecks_target_group_arn" {
  value = var.DEPLOY_MDSS_INGRESS ? aws_lb_target_group.systemchecks_target_group.0.arn : null
}

output "mdcore_target_group_arn" {
  value = aws_lb_target_group.mdcore_target_group.0.arn
}
