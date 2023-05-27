# ami_arch에 따라 최신 ami를 가져옵니다.
data "aws_ami" "this" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "architecture"
    values = [var.ami_arch]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }
}

locals {
    ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.this.id
}

# 생성한 sg와 추가적으로 사용자가 등록한 sg를 합치기 위한 local 변수입니다.
locals {
    security_groups = compact(distinct(concat([
        aws_security_group.this.id,
    ], var.security_group_additional_ids)))
}

# tag를 설정합니다.
locals {
    tags = merge(
        var.tags,
        {
            "Name"        = "${var.name}"
            "Team"        = "${var.team}"
            "Service"     = "${var.service}"
            "Environment" = "${var.env}"
            "Created"     = formatdate("YY-MM-DD", timestamp())
        },
    )

    asg_tags = [
        for tag in keys(local.tags):
            tomap({
                "key" = tag
                "value" = element(values(local.tags), index(keys(local.tags), tag))
                "propagate_at_launch" = true
            })
    ]
}



# SG
resource "aws_security_group" "this" {
  name = "${var.service}-${var.env}"
  description = "for terraform test"
  vpc_id = "${var.vpc_id}"

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# IAM
data "aws_iam_policy_document" "this" {
  statement {
    sid     = "EC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name = "${var.env}-${var.service}"

  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role = aws_iam_role.this.name

    # 기본적인 policy와 추가적으로 사용자가 등록한 policy를 같이 등록합니다.
    for_each = toset(compact(distinct(concat([
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    ], var.iam_role_additional_policies))))

    policy_arn = each.value

}

resource "aws_iam_instance_profile" "this" {
  name = "${var.env}-${var.service}"

  role = aws_iam_role.this.name
}

# Target Group
resource "aws_lb_target_group" "this" {
    name	= var.service
    port = var.port
    protocol = var.protocol
    vpc_id = var.vpc_id
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = ["jaejin.demo.io"]
    }
  }
}

# Launch Template
resource "aws_launch_template" "this" {
    name	= var.service

    image_id = local.ami_id

    network_interfaces {
	  security_groups = local.security_groups
	}
	
	key_name = var.key_name

    iam_instance_profile {
        name = aws_iam_role.this.id
    }

    # 여러 ebs를 붙일 수 있기에 dynamic을 사용합니다.
    dynamic "block_device_mappings" {
        for_each = var.ebs_block_device
        content {
            device_name  = lookup(block_device_mappings.value, "device_name", null)

            ebs {
                volume_type           = lookup(block_device_mappings.value, "volume_type", "gp3")
                volume_size           = lookup(block_device_mappings.value, "volume_size", 8)
                iops                  = lookup(block_device_mappings.value, "iops", 3000)
                throughput            = lookup(block_device_mappings.value, "throughput", 125)
                delete_on_termination = lookup(block_device_mappings.value, "delete_on_termination", true)
        
            }
        }
    }

    user_data = var.user_data

    tag_specifications {
        resource_type = "instance"

        tags = local.tags
    }

    tags = local.tags
}

# ASG
resource "aws_autoscaling_group" "this" {
    name	= var.service

    min_size = var.min
    max_size = var.max

    termination_policies = ["OldestInstance"]
    vpc_zone_identifier = var.subnet_ids
    target_group_arns = [aws_lb_target_group.this.arn]

    mixed_instances_policy {
        launch_template {
            launch_template_specification {
                launch_template_id = aws_launch_template.this.id
            }

            override {
                instance_type     = var.instance_type
            }
        }
    }

    dynamic "tag" {
        for_each = local.asg_tags
        content {
            key = tag.value.key
            value = tag.value.value
            propagate_at_launch = tag.value.propagate_at_launch
        }
    }
}

