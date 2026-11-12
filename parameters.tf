data "aws_kms_alias" "ssm" {
  count = length(local.secret_parameter_arns) == 0 ? 0 : 1

  name = "alias/aws/ssm"
}

data "aws_iam_policy_document" "ea_parameters" {
  count = length(local.secret_parameter_arns) == 0 ? 0 : 1

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = local.secret_parameter_arns
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      data.aws_kms_alias.ssm[0].target_key_arn,
    ]
  }
}

resource "aws_iam_policy" "ea_parameters" {
  count = length(local.secret_parameter_arns) == 0 ? 0 : 1

  name        = "${var.project}-${var.environment}-ea-ssm-parameters"
  description = "Allows the EA task execution role to read SecureString parameters"
  policy      = data.aws_iam_policy_document.ea_parameters[0].json
}

resource "aws_iam_role_policy_attachment" "ea_parameters" {
  count = length(local.secret_parameter_arns) == 0 ? 0 : 1

  policy_arn = aws_iam_policy.ea_parameters[0].arn
  role       = aws_iam_role.this.name
}
