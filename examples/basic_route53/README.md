# Basic example with Route53 and ACM

How to test:
- run `aws configure` to setup aws credentials. Specify `eu-west-1` as a region.
- create the SecureString parameters named in `main.tf` before planning. `plan` checks that each one exists and does not read the value.
- point `route53_domain_name` and `route53_zoneid` at a hosted zone you control.
- run `terraform plan`
- run `terraform apply` (time of creation ~5 min)
- Once test is over run `terraform destroy` (time of deletion ~3 min)
