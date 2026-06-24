output "role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.this.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile (created when the trust policy name contains 'ec2')"
  value       = local.needs_instance_profile ? aws_iam_instance_profile.this[0].arn : null
}

output "managed_policy_arns" {
  description = "ARNs of the managed policies automatically applied based on the trust policy"
  value       = local.managed_policy_arns
}
