resource "tls_private_key" "jwt_signing" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "jwt_signing" {
  private_key_pem = tls_private_key.jwt_signing.private_key_pem

  validity_period_hours = 87600

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]

  subject {
    common_name  = "KalexLab IdP JWT Signing"
    organization = "KalexLab"
  }
}

resource "authentik_certificate_key_pair" "jwt_signing" {
  name             = "jwt_signing"
  certificate_data = tls_self_signed_cert.jwt_signing.cert_pem
  key_data         = tls_private_key.jwt_signing.private_key_pem
}
