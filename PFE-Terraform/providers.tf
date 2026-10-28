terraform {
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "0.5.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "cloudstack" {
  api_url    = var.api_url
  api_key    = var.api_key
  secret_key = var.secret_key

}
