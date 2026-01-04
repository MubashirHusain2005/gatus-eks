terraform destroy \
  -target=helm_release.cert_manager \
  -target=helm_release.nginx_ingress \
  -target=helm_release.external_dns \
  -target=kubectl_manifest.ingress \
  -target=kubectl_manifest.service \
  -target=kubectl_manifest.deployment \
  -target=kubectl_manifest.namespace


----

kubectl delete crd \
certificaterequests.cert-manager.io \
certificates.cert-manager.io \
challenges.acme.cert-manager.io \
clusterissuers.cert-manager.io \
issuers.cert-manager.io \
orders.acme.cert-manager.io

kubectl delete validatingwebhookconfiguration --all
kubectl delete mutatingwebhookconfiguration --all

---

terraform destroy -auto-approve


