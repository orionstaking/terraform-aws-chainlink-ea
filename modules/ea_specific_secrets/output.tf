output "secrets" {
  value = [
    for secret, arn in zipmap(
      sort(keys(aws_secretsmanager_secret.this)),
      sort(values(aws_secretsmanager_secret.this)[*]["arn"])) :
      { "name" = secret, "valueFrom" = arn }
  ]
}
