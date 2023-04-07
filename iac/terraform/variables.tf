variable "location" {
  description = ""
  type        = string
}

variable "uniquer" {
  description = ""
  type        = string
  default     = null
}

variable "resources_prefix" {
  description = ""
  type        = string
  default     = null
}

variable "docker_registry_server_url" {
  description = ""
  type        = string
  default     = null
}

variable "docker_registry_server_username" {
  description = ""
  type        = string
  default     = null
}

variable "docker_registry_server_password" {
  description = ""
  type        = string
  default     = null
  sensitive   = true
}

variable "mssql_server_administrator_login" {
  description = ""
  type        = string
  default     = null
}

variable "mssql_server_administrator_login_password" {
  description = ""
  type        = string
  default     = null
  sensitive   = true
}

variable "apipoi_base_image_tag" {
  description = ""
  type        = string
  default     = null
}

variable "apitrips_base_image_tag" {
  description = ""
  type        = string
  default     = null
}

variable "apiuserjava_base_image_tag" {
  description = ""
  type        = string
  default     = null
}

variable "apiuserprofile_base_image_tag" {
  description = ""
  type        = string
  default     = null
}
