terraform {
  backend "s3" {
    endpoint                    = "storage.yandexcloud.net"
    bucket                      = "otusterraform"
    region                      = "ru-central1"
    key                         = "prod/terraform.tfstate"
    access_key                  = "your_access_key"
    secret_key                  = "your_secret_key"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
