#variable "db_username" {
#  description = "The username for the database"
#  type        = string
#  sensitive   = true
#  # Left as example, default now moved to .tfvars file
#  #default     = "dbuser"
#}
#
#variable "db_password" {
#  description = "The password for the database"
#  type        = string
#  sensitive   = true
#}

variable "db_name" {
  description = "The name of the database"
  type        = string
  sensitive   = true
  default     = "memoverflow_stage"
}