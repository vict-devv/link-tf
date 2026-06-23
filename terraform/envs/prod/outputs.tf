output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca" {
  value     = module.eks.cluster_ca_certificate
  sensitive = true
}

output "eks_oidc_issuer_url" {
  value = module.eks.oidc_issuer_url
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_issuer_arn
}

output "ecr_shortener_api_url" {
  value = module.ecr_shortener_api.repository_url
}

output "ecr_analytics_worker_url" {
  value = module.ecr_analytics_worker.repository_url
}

output "ecr_stats_api_url" {
  value = module.ecr_stats_api.repository_url
}
