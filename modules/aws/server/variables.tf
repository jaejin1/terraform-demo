# Common
variable "name" {
    type = string
}

variable "service" {
    type = string
}

variable "env" {
    type = string
}

variable "tags" {
    type    = map(string)
    default = {}
}

variable "team" {
    type = string
    default = ""
}

variable "vpc_id" {
    type = string
}


# launch template
variable "ami_arch" {
    description = "생성할 ami의 arch"
    type = string
}

variable "ami_id" {
    type = string
}

variable "key_name" {
    type = string
}

variable "security_group_additional_ids" {
  type        = list(string)
}


# IAM

variable "iam_role_additional_policies" {
  type        = list(string)
  default     = []
}

# variable "root_block_device" {
#   type = list(map(string))
# }

variable "ebs_block_device" {
  type = list(map(string))
}

variable "user_data" {
  type = string
  default = ""
}

# ASG
variable "min" {
  type = number
  default = 0
}

variable "max" {
  type = number
  default = 0
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "instance_type" {
    type = string
}

# elb target group
variable "port" {
  type = number
  default = 80
}

variable "protocol" {
    type = string
    default = "HTTP"
}

# elb
variable "listener_arn" {
  type = string
}