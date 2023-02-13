# https://stackoverflow.com/questions/46653464/terraform-how-can-i-read-variables-into-terraform-from-a-yaml-file-or-from-a-d
locals {
  config  = yamldecode(file("variables.yaml"))
}