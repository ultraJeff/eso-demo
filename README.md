# External Secrets Operator Demo

This demo showcases the External Secrets Operator (ESO) for Red Hat OpenShift, which synchronizes secrets from external secret management systems into Kubernetes Secrets.

## Overview

The demo uses the **Kubernetes provider** which uses a Kubernetes namespace as the "source of truth" (simulating an external vault like HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault).

```
┌─────────────────────────────────────────────────────────────────┐
│                     secret-store namespace                       │
│  (Simulates external secret manager like Vault/AWS)             │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ database-        │  │ api-keys     │  │ tls-certificates │  │
│  │ credentials      │  │              │  │                  │  │
│  └────────┬─────────┘  └──────┬───────┘  └────────┬─────────┘  │
└───────────┼────────────────────┼──────────────────┼─────────────┘
            │                    │                  │
            │    ClusterSecretStore (ESO)          │
            │    ────────────────────────          │
            ▼                    ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                        eso-demo namespace                        │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ database-        │  │ api-keys     │  │ app-tls          │  │
│  │ credentials      │  │              │  │                  │  │
│  │ (synced)         │  │ (synced)     │  │ (synced)         │  │
│  └────────┬─────────┘  └──────┬───────┘  └────────┬─────────┘  │
│           │                   │                   │             │
│           └───────────────────┼───────────────────┘             │
│                               ▼                                  │
│                     ┌─────────────────┐                         │
│                     │   sample-app    │                         │
│                     │   (uses secrets)│                         │
│                     └─────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

## Components

| Resource | Description |
|----------|-------------|
| `secret-store` namespace | Holds the "source" secrets (simulates Vault) |
| `ClusterSecretStore` | Configures ESO to read from the secret-store namespace |
| `ExternalSecret` | Defines what secrets to sync and how |
| `sample-app` | Demo app that consumes the synced secrets |

## Secrets Demonstrated

1. **Database Credentials** - Username, password, host, port
2. **API Keys** - Multiple third-party API keys (Stripe, SendGrid, OpenAI)
3. **TLS Certificates** - Certificate and private key

## Prerequisites

The External Secrets Operator for Red Hat OpenShift must be installed. This demo includes the `ExternalSecretsConfig` resource that deploys the ESO controller pods.

## Installation

```bash
# Deploy the demo (includes ExternalSecretsConfig, source secrets, and sample app)
oc apply -k .

# Wait for secrets to sync
sleep 10

# Check ExternalSecret status
oc get externalsecrets -n eso-demo

# Check the synced secrets
oc get secrets -n eso-demo

# View the sample app logs
oc logs -n eso-demo deploy/sample-app
```

## Verification

```bash
# Check ClusterSecretStore is valid
oc get clustersecretstores kubernetes-secret-store

# Check ExternalSecrets are synced
oc get externalsecrets -n eso-demo -o wide

# Compare source and synced secrets
echo "=== Source Secret ==="
oc get secret database-credentials -n secret-store -o jsonpath='{.data.username}' | base64 -d
echo ""
echo "=== Synced Secret ==="
oc get secret database-credentials -n eso-demo -o jsonpath='{.data.DB_USERNAME}' | base64 -d
```

## Key Features Demonstrated

1. **Secret Transformation** - Source keys are renamed (e.g., `username` → `DB_USERNAME`)
2. **Multiple Sync Strategies** - Individual keys vs. `dataFrom` (sync all keys)
3. **Different Secret Types** - Opaque secrets and TLS secrets
4. **Refresh Interval** - Automatic secret rotation (1h, 30m, 24h)
5. **Templating** - Custom labels and metadata on synced secrets

## Real-World Use Cases

In production, you would replace the Kubernetes provider with:

| Provider | Use Case |
|----------|----------|
| **HashiCorp Vault** | Enterprise secret management |
| **AWS Secrets Manager** | AWS-native applications |
| **Azure Key Vault** | Azure-native applications |
| **GCP Secret Manager** | GCP-native applications |
| **CyberArk** | Enterprise PAM integration |
| **1Password** | Team secret sharing |

## Cleanup

```bash
oc delete -k .
```

