# output "security_group_id" {
#     value = aws_security_group.this.id
# }



output "target_group_name" {
    value = aws_lb_target_group.this.name
    # value = join("", aws_lb_target_group.this.*.name)
}

# output "launch_template_name" {
#     value = aws_launch_template.this.name
# }

# output "asg_name" {
#     value = aws_autoscaling_group.this.name
# }

output "autoscaling_group_id" {
    value = aws_autoscaling_group.this.id
    # value = join("", [ for asg in aws_autoscaling_group.this : asg.id ])
    # value =  join("", aws_autoscaling_group.this.*.id)
}