# vpc id를 가져오기 위해 name으로 검색합니다.
data "aws_vpc" "vpc" {
    filter {
        name   = "tag:Name"
        values = [local.tf_vars.demo.vpc.name]
    }
}


# vpc에 속해있는 subnet들을 가져오기 위해 subnet_private_filter 라는 값을 가지고 검색합니다.
data "aws_subnets" "private" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.vpc.id]
    }

    filter {
        name = "tag:Name"
        values = [format("%s", local.tf_vars.demo.vpc.subnet_private_filter)]
    }
}

# ec2 생성시 필요한 user data script를 파일로 읽어옵니다.
data "local_file" "user_data_script" {
    filename = "${path.module}/scripts/user_data.sh"
}

# tf_vars를 yaml로 관리 하여 파일을 읽어옵니다.
locals {
    tf_vars = yamldecode(file(var.tf_vars))
}

# subnet id와 vpc id를 local value로 등록합니다.
locals {
    subnet_ids = distinct(data.aws_subnets.private.ids)
    vpc_id = data.aws_vpc.vpc.id
}

# module
# server, route53, deploy 정도만 모듈로 구분하여 사용하였습니다.

# server - Launch Template을 통한 ASG 생성 및 target group 생성까지 도와주는 모듈입니다.
module "server" {
    source =  "../../modules/aws/server"

    # variable yaml 파일에 여러 server를 등록 할 수 있게 합니다.
    # yaml파일의 demo.server 하위로 설정하면 됩니다.
    for_each = { 
        for k, v in local.tf_vars.demo.server:
        k => v
    }

    # common
    name = local.tf_vars.demo.name
    service = each.key
    env = local.tf_vars.demo.env
    vpc_id = local.vpc_id

    # lt
    ami_arch = each.value.ami_arch
    ami_id = each.value.ami_id
    key_name = each.value.key_name
    # root_block_device = var.root_block_device
    ebs_block_device = each.value.ebs.ebs_block_device

    security_group_additional_ids = each.value.security_group_additional_ids
    user_data = data.local_file.user_data_script.content_base64

    # asg
    subnet_ids = local.subnet_ids
    min = each.value.asg.min
    max = each.value.asg.max
    instance_type = each.value.asg.instance_type

    iam_role_additional_policies = each.value.iam_role_additional_policies

    # target group
    port = each.value.target_group.port
    protocol = each.value.target_group.protocol

    # elb
    listener_arn = each.value.elb.listener_arn
}

# route53 - 따로 생성은 안하고 값을 받아와서 route 53 레코드를 등록하는 모듈입니다.
module "route53" {
    source = "../../modules/aws/route53"

    record_name = local.tf_vars.demo.route53.record.name
    record_type = local.tf_vars.demo.route53.record.type

    host_zone_id = local.tf_vars.demo.route53.host_zone_id

    elb_alias_name = local.tf_vars.demo.route53.elb_alias_name
    elb_alias_zone_id =local.tf_vars.demo.route53.elb_alias_zone_id
}

# 배포를 위한 codedeploy를 생성해주는 모듈입니다.
module "deploy" {
    source = "../../modules/aws/deploy"

    # variable yaml 파일에 여러 server를 등록 할 수 있게 합니다.
    # yaml파일의 demo.server 하위로 설정하면 됩니다.
    for_each = { 
        for k, v in local.tf_vars.demo.server:
        k => v
    }
 
    service = each.key
    env = local.tf_vars.demo.env

    target_group_name = module.server.*[0][each.key].target_group_name
    autoscaling_group_id = module.server.*[0][each.key].autoscaling_group_id
}
