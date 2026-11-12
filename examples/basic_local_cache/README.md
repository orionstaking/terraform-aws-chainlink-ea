# Basic example with local cache

How to test:
- run `aws configure` to setup aws credentials. Specify `eu-west-1` as a region.
- create the SecureString parameters named in `main.tf` before planning. `plan` checks that each one exists and does not read the value.
- run `terraform plan`
- run `terraform apply` (time of creation ~5 min)
- Once test is over run `terraform destroy` (time of deletion ~3 min)
