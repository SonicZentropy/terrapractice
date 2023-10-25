variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
  default     = "dbuser" # For convenience in dev only, do not do this in production
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
  default     = "dbp4ssw0rd" # For convenience in dev only, do not do this in production
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  sensitive   = true
  default     = "memoverflow_prod" # For convenience in dev only, do not do this in production
}