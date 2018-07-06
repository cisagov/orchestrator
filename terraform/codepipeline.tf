# The S3 bucket where build artifacts are stored
resource "aws_s3_bucket" "pipeline_bucket" {
  bucket = "orchestrator-codepipeline"
  acl = "private"
  force_destroy = "true"

  # Destroy objects after 30 days
  lifecycle_rule {
    enabled = true

    expiration {
      days = 30
    }
  }

  tags = "${var.tags}"
}

# IAM policy document that disallows unencrypted object uploads and
# insecure connections.
data "aws_iam_policy_document" "pipeline_bucket_doc" {
  # Deny unencrypted uploads
  statement {
    effect = "Deny"

    principals {
      type = "AWS"
      identifiers = [
        "*"
      ]
    }
    
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.pipeline_bucket.arn}/*"
    ]

    condition {
      test = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values = [
        "aws:kms"
      ]
    }
  }

  # Deny unsecure connections
  statement {
    effect = "Deny"

    principals {
      type = "AWS"
      identifiers = [
        "*"
      ]
    }
    
    actions = [
      "s3:*"
    ]

    resources = [
      "${aws_s3_bucket.pipeline_bucket.arn}/*"
    ]

    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

# This is the policy for our pipeline bucket
resource "aws_s3_bucket_policy" "pipeline_bucket_policy" {
  bucket = "${aws_s3_bucket.pipeline_bucket.id}"
  policy = "${data.aws_iam_policy_document.pipeline_bucket_doc.json}"
}

# IAM assume role policy document for the role we're creating
data "aws_iam_policy_document" "pipeline_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

# The role we're creating
resource "aws_iam_role" "pipeline_role" {
  assume_role_policy = "${data.aws_iam_policy_document.pipeline_assume_role_doc.json}"
}

# IAM policy document that that allows some S3 permissions on our
# pipeline bucket.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "pipeline_s3_doc" {
  statement {
    effect = "Allow"
    
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.pipeline_bucket.arn}/*"
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_role_policy" "pipeline_s3_policy" {
  role = "${aws_iam_role.pipeline_role.id}"
  policy = "${data.aws_iam_policy_document.pipeline_s3_doc.json}"
}

# IAM policy document that that allows some CodeBuild permissions.
# This will be applied to the role we are creating.
data "aws_iam_policy_document" "pipeline_codebuild_doc" {
  statement {
    effect = "Allow"
    
    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds"
    ]

    resources = [
      "${aws_codebuild_project.project.id}"
    ]
  }
}

# The CodeBuild policy for our role
resource "aws_iam_role_policy" "pipeline_codebuild_policy" {
  role = "${aws_iam_role.pipeline_role.id}"
  policy = "${data.aws_iam_policy_document.pipeline_codebuild_doc.json}"
}

# The CodePipeline for CI/CD
resource "aws_codepipeline" "pipeline" {
  name = "orchestrator"
  role_arn = "${aws_iam_role.pipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.pipeline_bucket.bucket}"
    type = "S3"
  }

  # Grab the source code
  stage {
    name = "Source"
    action {
      name = "Source"
      category = "Source"
      owner = "ThirdParty"
      provider = "GitHub"
      version = "1"
      output_artifacts = [
        "source"
      ]

      configuration {
        Owner = "dhs-ncats"
        Repo = "orchestrator"
        Branch = "feature/codepipeline"
        PollForSourceChanges = "true"
      }
    }
  }

  # Run the CodeBuild project
  stage {
    name = "Build"
    action {
      name = "CodeBuild"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["source"]
      output_artifacts = ["build"]

      configuration {
        ProjectName = "orchestrator"
      }
    }
  }
}
