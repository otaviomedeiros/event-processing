variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "queue" {
  type = object({
    name = string
    arn  = string
  })
}