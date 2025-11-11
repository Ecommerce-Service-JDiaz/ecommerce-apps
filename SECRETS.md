# Secrets Requeridos

Este proyecto usa GitHub Actions para desplegar Zipkin en tres ambientes (dev, stage, prod). Los secrets se almacenan en **Azure Key Vault** (excepto `AZURE_CREDENTIALS` que se mantiene en GitHub Secrets).

## Configuración

### 1. GitHub Secrets

Solo necesitas configurar **1 secret** en GitHub:

#### `AZURE_CREDENTIALS` (JSON)
- **Descripción**: Credenciales del Service Principal con acceso a los clusters AKS y al Key Vault
- **Ubicación**: GitHub → Settings → Secrets and variables → Actions → New repository secret
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

**IMPORTANTE**: El Service Principal debe tener permisos para:
- Acceder a los clusters AKS (dev, stage, prod)
- Listar recursos en el Resource Group `ecommerce-rg-global` (para encontrar el Key Vault)
- Leer secrets del Azure Key Vault (se detecta automáticamente)

### 2. Azure Key Vault

Los siguientes secrets deben estar configurados en el Key Vault:

**Key Vault**: Se detecta automáticamente (el único Key Vault en el Resource Group)  
**Resource Group**: `ecommerce-rg-global`

> **Nota**: El pipeline busca dinámicamente el Key Vault en el Resource Group `ecommerce-rg-global`. Si hay un rollback y el nombre del Key Vault cambia, el pipeline lo detectará automáticamente.

#### Secrets Requeridos en el Key Vault:

| Nombre en Key Vault | Descripción | Ejemplo |
|---------------------|-------------|---------|
| `AZURE-RESOURCE-GROUP-DEV` | Resource Group del cluster **dev** | `rg-aks-dev` |
| `AZURE-RESOURCE-GROUP-STAGE` | Resource Group del cluster **stage** | `rg-aks-stage` |
| `AZURE-RESOURCE-GROUP-PROD` | Resource Group del cluster **prod** | `rg-aks-prod` |
| `AKS-CLUSTER-NAME-DEV` | Nombre del cluster AKS en **dev** | `aks-dev` |
| `AKS-CLUSTER-NAME-STAGE` | Nombre del cluster AKS en **stage** | `aks-stage` |
| `AKS-CLUSTER-NAME-PROD` | Nombre del cluster AKS en **prod** | `aks-prod` |

#### Cómo agregar/actualizar secrets en el Key Vault:

Primero, obtén el nombre del Key Vault dinámicamente:

```bash
RESOURCE_GROUP="ecommerce-rg-global"

# Obtener el nombre del Key Vault
KEY_VAULT_NAME=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)

echo "Key Vault encontrado: $KEY_VAULT_NAME"

# Ejemplo: Agregar Resource Group de DEV
az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "AZURE-RESOURCE-GROUP-DEV" \
  --value "rg-aks-dev"

# Ejemplo: Agregar Cluster Name de DEV
az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "AKS-CLUSTER-NAME-DEV" \
  --value "aks-dev"
```

#### Verificar secrets en el Key Vault:

```bash
RESOURCE_GROUP="ecommerce-rg-global"

# Obtener el nombre del Key Vault
KEY_VAULT_NAME=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)

# Listar todos los secrets
az keyvault secret list --vault-name "$KEY_VAULT_NAME" -o table
```

## Resumen

| Ubicación | Secret | Uso |
|-----------|--------|-----|
| **GitHub Secrets** | `AZURE_CREDENTIALS` | Autenticación en Azure (Service Principal) |
| **Azure Key Vault** | `AZURE-RESOURCE-GROUP-DEV` | Resource Group del cluster **dev** |
| **Azure Key Vault** | `AZURE-RESOURCE-GROUP-STAGE` | Resource Group del cluster **stage** |
| **Azure Key Vault** | `AZURE-RESOURCE-GROUP-PROD` | Resource Group del cluster **prod** |
| **Azure Key Vault** | `AKS-CLUSTER-NAME-DEV` | Nombre del cluster AKS en **dev** |
| **Azure Key Vault** | `AKS-CLUSTER-NAME-STAGE` | Nombre del cluster AKS en **stage** |
| **Azure Key Vault** | `AKS-CLUSTER-NAME-PROD` | Nombre del cluster AKS en **prod** |

**Total**: 1 secret en GitHub + 6 secrets en Azure Key Vault

## Permisos Requeridos

El Service Principal (`AZURE_CREDENTIALS`) debe tener:

1. **Permisos en los clusters AKS**:
   - Rol: `Azure Kubernetes Service RBAC Cluster Admin` o similar
   - Scope: Cada cluster AKS (dev, stage, prod)

2. **Permisos en el Key Vault**:
   - Política de acceso: `Get` y `List` en secrets
   - Puedes asignarlo con:
     ```bash
     RESOURCE_GROUP="ecommerce-rg-global"
     
     # Obtener el nombre del Key Vault
     KEY_VAULT_NAME=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
     
     # Asignar permisos al Service Principal
     az keyvault set-policy \
       --name "$KEY_VAULT_NAME" \
       --spn <clientId-del-service-principal> \
       --secret-permissions get list
     ```

## Buenas Prácticas

- El Service Principal debe tener únicamente los permisos necesarios (principio de menor privilegio).
- Rota las credenciales del Service Principal periódicamente.
- Los secrets en Key Vault se pueden rotar sin cambiar el código del workflow.
- Considera habilitar soft-delete y purge protection en el Key Vault para mayor seguridad.

## Troubleshooting

### Error: "Secret not found" en GitHub
- Verifica que `AZURE_CREDENTIALS` esté configurado en GitHub Secrets
- Verifica mayúsculas/minúsculas exactas

### Error: "No se encontró ningún Key Vault en el Resource Group"
- Verifica que exista al menos un Key Vault en el Resource Group `ecommerce-rg-global`
- Verifica que el Service Principal tenga permisos para listar recursos en ese Resource Group

### Error: "No se pudieron obtener los Resource Groups del Key Vault"
- Verifica que el Service Principal tenga permisos `Get` y `List` en el Key Vault
- Verifica que el Key Vault exista y esté accesible en el Resource Group `ecommerce-rg-global`
- Verifica que los nombres de los secrets en el Key Vault sean exactamente:
  - `AZURE-RESOURCE-GROUP-DEV` (con guiones y mayúsculas)
  - `AZURE-RESOURCE-GROUP-STAGE`
  - `AZURE-RESOURCE-GROUP-PROD`
  - `AKS-CLUSTER-NAME-DEV`
  - `AKS-CLUSTER-NAME-STAGE`
  - `AKS-CLUSTER-NAME-PROD`

### Error: "Authentication failed"
- Asegúrate de que `AZURE_CREDENTIALS` contenga el JSON completo y válido
- Verifica que el Service Principal no esté expirado o deshabilitado

### Error: "Cannot connect to AKS"
- Revisa que los valores en el Key Vault sean correctos (Resource Group y Cluster Name)
- Verifica que el Service Principal tenga permisos sobre el cluster específico del ambiente
- Verifica que el cluster AKS esté accesible y en ejecución

### Verificar permisos del Service Principal en Key Vault

```bash
RESOURCE_GROUP="ecommerce-rg-global"

# Obtener el nombre del Key Vault
KEY_VAULT_NAME=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)

# Ver políticas del Key Vault
az keyvault show --name "$KEY_VAULT_NAME" --query properties.accessPolicies

# Verificar que el SP tenga acceso
az keyvault secret show \
  --vault-name "$KEY_VAULT_NAME" \
  --name AZURE-RESOURCE-GROUP-DEV \
  --query "value" -o tsv
```
