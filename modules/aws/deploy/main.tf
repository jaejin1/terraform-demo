data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.service}-role"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.this.name
}


resource "aws_codedeploy_app" "this" {
   compute_platform = "Server"
   name = var.service
}


resource "aws_codedeploy_deployment_group" "this" {
    app_name              = aws_codedeploy_app.this.name
    deployment_group_name = "${var.env}-${var.service}-demo-group"
    service_role_arn      = aws_iam_role.this.arn
    
    deployment_style {
        deployment_option = "WITH_TRAFFIC_CONTROL"
        deployment_type   = "IN_PLACE"
    }

    load_balancer_info {
        target_group_info {
            name = var.target_group_name
        }
    }

    autoscaling_groups = [var.autoscaling_group_id]
}