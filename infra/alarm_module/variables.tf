variable "max_bedrock_ms" {
  type        = number
  default     = 20000
  description = "Alarmen går hvis bedrock i snitt bruker mer enn dette i millisekunder"
}

variable "alarm_email" {
  type        = string
  description = "Mailadressen som får varsel når alarmen går"
}

variable "namespace" {
  type        = string
  description = "Namespace for metrikken fra oppgave 3A, brukes også foran navnene"

}