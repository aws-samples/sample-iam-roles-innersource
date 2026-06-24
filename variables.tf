variable "role_name" {
  description = "Name of the IAM Role to create"
  type        = string

  validation {
    condition     = length(var.role_name) >= 1 && length(var.role_name) <= 64
    error_message = "The IAM Role name must be between 1 and 64 characters. Current length: ${length(var.role_name)} characters."
  }

  validation {
    condition     = can(regex("^[\\w+=,.@-]+$", var.role_name))
    error_message = "The IAM Role name may only contain alphanumeric characters and the following special characters: + = , . @ -. Provided name: '${var.role_name}'."
  }
}

variable "role_path" {
  description = "Path for the IAM Role. Must begin and end with '/'. Defaults to '/' (the AWS default)."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/([\\w+=,.@-]+/)*$", var.role_path))
    error_message = "role_path must begin and end with '/' (e.g. '/' or '/platform/'). Provided: '${var.role_path}'."
  }
}

variable "identity_policy" {
  description = "List of inline policies to attach to the role. Each item represents a policy with its template and resources."
  type = list(object({
    policy     = string
    resources  = list(string)
    parameters = optional(map(string), {})
  }))
  validation {
    condition = alltrue([
      for policy in var.identity_policy :
      can(regex("^[a-z0-9]+/[a-z0-9]+$", policy.policy))
    ])
    error_message = "The policy field must follow the 'service/policy' format (e.g. s3/default, dynamodb/readonly)."
  }
  validation {
    condition = alltrue(flatten([
      for policy in var.identity_policy : [
        for arn in policy.resources :
        can(regex("^arn:aws[a-z-]*:[a-z0-9-]+:[a-z0-9-]*:[0-9]*:.+$", arn)) && !can(regex("\\*", arn))
      ]
    ]))
    error_message = "All resources in identity_policy[*].resources must be valid AWS ARNs in the format: arn:partition:service:region:account-id:resource. Wildcards (*) are not allowed."
  }
}

variable "trust_policy" {
  description = "Trust policy to use. Can be a simple service (string) or an object with policy and parameters."
  type = object({
    policy = string
    parameters = optional(list(map(string)), [
      {}
    ])
  })
}

variable "tags" {
  description = "Tags to apply to all created resources"
  type        = map(string)
}
