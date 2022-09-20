variable "env" {
  type = string
}

variable "queue" {
  type = object({
    name = string
    arn  = string
  })
}