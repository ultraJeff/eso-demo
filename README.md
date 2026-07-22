# External Secrets Operator Demo

Demonstrates the External Secrets Operator (ESO) for Red Hat OpenShift, syncing secrets from external providers into Kubernetes Secrets.

## Structure

```
eso-demo/
├── base/                        # Shared: ESO config, namespace, sample app
├── overlays/
│   ├── kubernetes/              # Kubernetes provider (simulated vault)
│   └── vault/                   # HashiCorp Vault provider (Wing)
```

### Overlays

**`overlays/kubernetes/`** — Uses a Kubernetes namespace as a simulated secret store. Good for demos on a fresh cluster with no external dependencies. Run `setup-demo-secrets.sh` after deploying to create the fake source secrets.

**`overlays/vault/`** — Connects to a real HashiCorp Vault instance. Configured for Wing (`192.168.8.100:8200`) using token auth via a `vault-token` K8s secret.

## Prerequisites

- External Secrets Operator for Red Hat OpenShift installed
- For the Vault overlay:
  - Vault running and unsealed
  - Secrets stored in Vault under `secret/eso-demo/`
  - A `vault-token` secret in the `eso-demo` namespace with a read-only Vault token
  - Network policy allowing ESO egress to Vault (ESO operator denies all egress by default)

## Deploying

### Vault overlay (production-like)

```bash
# 1. Create the vault-token secret (not in git)
oc create secret generic vault-token \
  --from-literal=token=<your-vault-token> \
  -n eso-demo

# 2. Annotate so ArgoCD doesn't prune it
oc annotate secret vault-token -n eso-demo \
  argocd.argoproj.io/compare-options=IgnoreExtraneous

# 3. Add network policy for ESO -> Vault egress
cat <<EOF | oc apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: eso-allow-vault-egress
  namespace: external-secrets
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: external-secrets
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 192.168.8.100/32
      ports:
        - protocol: TCP
          port: 8200
EOF

# 4. Deploy via ArgoCD or directly
oc apply -k overlays/vault/
```

### Kubernetes overlay (standalone demo)

```bash
oc apply -k overlays/kubernetes/
# Then create the simulated source secrets:
./overlays/kubernetes/setup-demo-secrets.sh
```

## Verification

```bash
# Check ClusterSecretStore is valid
oc get clustersecretstore

# Check ExternalSecrets are synced
oc get externalsecrets -n eso-demo

# View sample app consuming the secrets
oc logs -n eso-demo deploy/sample-app
```

## Secrets Demonstrated

| Secret | Type | Refresh |
|--------|------|---------|
| Database credentials | Opaque (key-mapped) | 1h |
| API keys | Opaque (extracted) | 30m |
| TLS certificates | kubernetes.io/tls | 24h |
