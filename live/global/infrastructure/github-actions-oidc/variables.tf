# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "allowed_repos_branches" {
  description = "GitHub repos/branches allowed to assume the IAM role."
  type = list(object({
    org    = string
    repo   = string
    branch = string
  }))

  #Example:
  #allowed_repos_branches = [
  #  {
  #    org    = "SonicZentropy"
  #    repo   = "terraCI"
  #    branch = "ch6"
  #  }
  #]
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name used to namespace all the resources created by this module"
  type        = string
  default     = "github-actions-oidc-memoverrun"
}
