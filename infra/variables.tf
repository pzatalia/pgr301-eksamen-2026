variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS-region for alle ressurser"
}

variable "project_name" {
  type        = string
  default     = "wishifai"
  description = "Prosjektnavn brukes i ressursnavn"
}

variable "kandidatnummer" {
  type        = string
  default     = "19"
  description = "Kandidatnummer, gir unike navn i den delte kontoen"
}

variable "ecr_repository_url" {
  type        = string
  default     = "244530008913.dkr.ecr.eu-west-1.amazonaws.com/wishifai-0501"
  description = "ECR-repo med image: Oppgave 1B"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "image-tag som skal kjøre. CI sender inn commit-SHA"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.image_tag))
    error_message = "image_tag må være en gyldig docker-tag"
  }
}

variable "alarm_email" {
  type        = string
  default     = "pzatalia@gmail.com"
  description = "Mailen som blir varslet når alarmen går"

}