locals {
  tags = merge(
      {
          Name = var.vm_name
      },
      var.tags
  )
}

variable "vm_name" {
  type = string
}

variable "tags" {
  default = {}
  type = map(string)
}

variable "key_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
    type = string
}