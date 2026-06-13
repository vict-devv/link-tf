terraform {
  backend "s3" {
    bucket       = "linkr-tf-state-064160141787"
    key          = "env/dev/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
