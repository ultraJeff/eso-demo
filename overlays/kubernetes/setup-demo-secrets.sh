#!/bin/bash
# Creates the fake demo secrets in the secret-store namespace.
# Run this after deploying the kubernetes overlay.
# These are not real credentials — just demo placeholders.

set -euo pipefail

oc apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: secret-store
type: Opaque
stringData:
  username: db-admin
  password: supersecret123
  host: postgres.database.svc.cluster.local
  port: "5432"
---
apiVersion: v1
kind: Secret
metadata:
  name: api-keys
  namespace: secret-store
type: Opaque
stringData:
  stripe-api-key: sk_live_abc123xyz
  sendgrid-api-key: SG.abcdefghijklmnop
  openai-api-key: sk-proj-demo12345
---
apiVersion: v1
kind: Secret
metadata:
  name: tls-certificates
  namespace: secret-store
type: kubernetes.io/tls
stringData:
  tls.crt: |
    -----BEGIN CERTIFICATE-----
    MIIDazCCAlOgAwIBAgIUdemo12345==
    -----END CERTIFICATE-----
  tls.key: |
    -----BEGIN RSA KEY PLACEHOLDER-----
    MIIEvgIBADANdemo67890==
    -----END RSA KEY PLACEHOLDER-----
EOF

echo "Demo secrets created in secret-store namespace."
