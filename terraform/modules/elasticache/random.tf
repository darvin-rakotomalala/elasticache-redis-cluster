###########################################
## RANDOM PASSWORD
###########################################

resource "random_password" "auth" {
  length           = 128
  special          = true
  override_special = "!&#$^<>-"
}
