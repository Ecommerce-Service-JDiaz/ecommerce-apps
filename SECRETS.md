# Secrets Requeridos

Este proyecto usa GitHub Actions para desplegar Zipkin en tres ambientes (dev, stage, prod). Cada ambiente está en un Resource Group y un cluster de AKS distinto, por lo que necesitas un conjunto de secrets por ambiente más las credenciales del Service Principal.

## GitHub Actions

Configura los secrets en tu repositorio:

1. GitHub → Settings → Secrets and variables → **Actions** → New repository secret
2. Repite para cada secret listado abajo.

### 1. `AZURE_CREDENTIALS` (JSON)
- **Descripción**: Credenciales del Service Principal con acceso a los tres clusters
- **Formato**:
  ```json
  {
    "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
  ```
- **Cómo obtenerlo**:
  ```bash
  az ad sp create-for-rbac \
    --name "github-actions-zipkin" \
    --role "Azure Kubernetes Service RBAC Cluster Admin" \
    --scopes /subscriptions/<subscription-id> \
    --sdk-auth
  ```
  > Guarda el JSON completo tal cual en el secret `AZURE_CREDENTIALS`.

### 2. Resource Groups por ambiente
| Secret | ¿Sensible? | Ejemplo |
|--------|------------|---------|
| `AZURE_RESOURCE_GROUP_DEV`   | No  | `rg-aks-dev`   |
| `AZURE_RESOURCE_GROUP_STAGE` | No  | `rg-aks-stage` |
| `AZURE_RESOURCE_GROUP_PROD`  | No  | `rg-aks-prod`  |

- Deben ser los nombres de los Resource Groups donde vive cada cluster de AKS.
- Aunque no son secretos, conviene guardarlos como secrets para mantener todo centralizado.

### 3. Nombres de los clusters AKS
| Secret | ¿Sensible? | Ejemplo |
|--------|------------|---------|
| `AKS_CLUSTER_NAME_DEV`   | No  | `aks-dev`   |
| `AKS_CLUSTER_NAME_STAGE` | No  | `aks-stage` |
| `AKS_CLUSTER_NAME_PROD`  | No  | `aks-prod`  |

- Deben coincidir exactamente con el nombre del cluster AKS en cada ambiente.

## Resumen

| Secret | Uso |
|--------|-----|
| `AZURE_CREDENTIALS` | Autenticación en Azure (Service Principal)
| `AZURE_RESOURCE_GROUP_DEV` | Resource Group del cluster **dev**
| `AZURE_RESOURCE_GROUP_STAGE` | Resource Group del cluster **stage**
| `AZURE_RESOURCE_GROUP_PROD` | Resource Group del cluster **prod**
| `AKS_CLUSTER_NAME_DEV` | Nombre del cluster AKS en **dev**
| `AKS_CLUSTER_NAME_STAGE` | Nombre del cluster AKS en **stage**
| `AKS_CLUSTER_NAME_PROD` | Nombre del cluster AKS en **prod**

Total: **7 secrets**.

## Buenas Prácticas

- El Service Principal debe tener únicamente los permisos necesarios (idealmente *Azure Kubernetes Service RBAC Cluster Admin* sobre cada cluster).
- Rota las credenciales del Service Principal periódicamente.
- Si agregas ambientes nuevos, sigue el patrón `AZURE_RESOURCE_GROUP_<ENV>` y `AKS_CLUSTER_NAME_<ENV>`.
- Considera almacenar estos secrets en Azure Key Vault y sincronizarlos automáticamente si tu gobernanza lo requiere.

## Troubleshooting

- **`Secret not found`**: Verifica mayúsculas/minúsculas y que el secret esté en el repositorio correcto.
- **`Authentication failed`**: Asegúrate de que `AZURE_CREDENTIALS` contenga el JSON completo y que el Service Principal no esté expirado.
- **`Cannot connect to AKS`**: Revisa que los nombres de Resource Group y Cluster coincidan con el ambiente seleccionado y que el Service Principal tenga permisos sobre ese cluster.
