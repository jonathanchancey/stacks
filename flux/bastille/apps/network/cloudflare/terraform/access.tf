resource "cloudflare_zero_trust_access_application" "kube_bastille" {
  account_id           = var.cloudflare_account_id
  name                 = "kube-bastille"
  type                 = "self_hosted"
  domain               = "kube-bastille.chancey.dev"
  app_launcher_visible = false
  session_duration     = "24h"

  policies = [
    { id = cloudflare_zero_trust_access_policy.amp_stacks.id, precedence = 1 },
  ]
}

resource "cloudflare_zero_trust_access_service_token" "amp_stacks" {
  account_id = var.cloudflare_account_id
  name       = "amp-stacks"
  duration   = "8760h"

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_zero_trust_access_policy" "amp_stacks" {
  account_id = var.cloudflare_account_id
  name       = "amp-stacks"
  decision   = "non_identity"

  include = [
    { service_token = { token_id = cloudflare_zero_trust_access_service_token.amp_stacks.id } },
  ]
}

output "amp_stacks_client_id" {
  value = cloudflare_zero_trust_access_service_token.amp_stacks.client_id
}

output "amp_stacks_client_secret" {
  value     = cloudflare_zero_trust_access_service_token.amp_stacks.client_secret
  sensitive = true
}
