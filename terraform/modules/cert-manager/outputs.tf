output "letsencrypt_staging_name" {
  value = kubectl_manifest.letsencrypt_staging.name
}

