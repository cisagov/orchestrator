# IAM assume role policy document for the role we're creating
data "aws_iam_policy_document" "build_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

# The role we're creating
resource "aws_iam_role" "build_role" {
  assume_role_policy = "${data.aws_iam_policy_document.build_assume_role_doc.json}"
}

# IAM policy document that that allows some S3 permissions on our
# pipeline bucket.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "build_s3_doc" {
  statement {
    effect = "Allow"
    
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.pipeline_bucket.arn}/*"
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_role_policy" "build_s3_policy" {
  role = "${aws_iam_role.build_role.id}"
  policy = "${data.aws_iam_policy_document.build_s3_doc.json}"
}

# The Cloudwatch log group for the CodeBuild project
resource "aws_cloudwatch_log_group" "logs" {
  name = "/aws/codebuild/${aws_codebuild_project.project.name}"
  retention_in_days = 30

  tags = "${var.tags}"
}

# IAM policy document that that allows some CloudWatch permissions.
# This will be applied to the role we are creating.
data "aws_iam_policy_document" "build_cloudwatch_doc" {
  statement {
    effect = "Allow"
    
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.logs.arn}",
      "${aws_cloudwatch_log_group.logs.arn}:*",
    ]
  }
}

# The CloudWatch policy for our role
resource "aws_iam_role_policy" "build_cloudwatch_policy" {
  role = "${aws_iam_role.build_role.id}"
  policy = "${data.aws_iam_policy_document.build_cloudwatch_doc.json}"
}

# IAM policy document that that allows some EC2 permissions on the
# instances in our build subnet in our build VPC.  This will be
# applied to the role we are creating.
data "aws_iam_policy_document" "build_vpc_doc" {
  statement {
    effect = "Allow"
    
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    
    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]
    
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*"
    ]
    
    condition {
      test = "StringEquals"
      variable = "ec2:Subnet"
      values = [
        "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/${aws_subnet.build_private_subnet.id}",
        # "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/${aws_subnet.build_public_subnet.id}",
      ]
    }

    condition {
      test = "StringEquals"
      variable = "ec2:AuthorizedService"
      values = [
        "codebuild.amazonaws.com"
      ]
    }
  }
}

# The CloudWatch policy for our role
resource "aws_iam_role_policy" "build_vpc_policy" {
  role = "${aws_iam_role.build_role.id}"
  policy = "${data.aws_iam_policy_document.build_vpc_doc.json}"
}

# The CodeBuild project
resource "aws_codebuild_project" "project" {
  name = "orchestrator"
  description = "AWS CodeBuild for the DHS-NCATS orchestrator project"
  build_timeout = "60"
  service_role = "${aws_iam_role.build_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/docker:17.09.0"
    type = "LINUX_CONTAINER"
    privileged_mode = "true"
  }

  source {
    type = "CODEPIPELINE"
  }

  vpc_config {
    vpc_id = "${aws_vpc.build_vpc.id}"
    
    security_group_ids = [
      "${aws_security_group.build_private_sg.id}"
    ]
    
    subnets = [
      "${aws_subnet.build_private_subnet.id}"
    ]
  }

  tags = "${var.tags}"
}
