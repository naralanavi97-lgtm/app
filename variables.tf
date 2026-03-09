variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP Zone"
  default     = "asia-south1-a"
}
