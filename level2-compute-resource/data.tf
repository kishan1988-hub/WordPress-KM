data "terraform_remote_state" "level1" {
  backend = "s3"

  config = {
    bucket = "terraform-remote-state-mk-1508"
    key    = "remote/wordpress-network/level1.tfstate"
    region = "ap-south-1"
  }
}
