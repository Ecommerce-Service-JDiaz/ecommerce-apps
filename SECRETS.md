# Variables Secretas Requeridas

Este documento lista todas las variables secretas que deben configurarse en GitHub Secrets o Azure DevOps para el despliegue de las aplicaciones en Kubernetes.

**IMPORTANTE**: Cada ambiente (dev, stage, prod) tiene su propio Resource Group y cluster de Kubernetes, por lo que se requieren variables separadas para cada uno.

## GitHub Secrets

Si estás usando GitHub Actions, configura los siguientes secrets en tu repositorio:

**Configuración:**
1. Ve a tu repositorio en GitHub
2. Settings → Secrets and variables → Actions → New repository secret
3. Agrega cada uno de los secrets listados abajo

### Secrets Requeridos

#### 1. `AZURE_CREDENTIALS` (Sensible)
- **Descripción**: Credenciales de Azure para autenticación (Service Principal)
- **Tipo**: JSON
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
  az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/{subscription-id} --sdk-auth
  ```

#### 2. Variables por Ambiente - Resource Groups

Cada ambiente tiene su propio Resource Group:

- **`AZURE_RESOURCE_GROUP_DEV`**
  - **Descripción**: Nombre del Resource Group de Azure para el ambiente DEV
  - **Tipo**: String
  - **Ejemplo**: `my-aks-resource-group-dev`
  - **Sensible**: No (pero recomendado como secret)

- **`AZURE_RESOURCE_GROUP_STAGE`**
  - **Descripción**: Nombre del Resource Group de Azure para el ambiente STAGE
  - **Tipo**: String
  - **Ejemplo**: `my-aks-resource-group-stage`
  - **Sensible**: No (pero recomendado como secret)

- **`AZURE_RESOURCE_GROUP_PROD`**
  - **Descripción**: Nombre del Resource Group de Azure para el ambiente PROD
  - **Tipo**: String
  - **Ejemplo**: `my-aks-resource-group-prod`
  - **Sensible**: No (pero recomendado como secret)

#### 3. Variables por Ambiente - Cluster Names

Cada ambiente tiene su propio cluster de Kubernetes:

- **`AKS_CLUSTER_NAME_DEV`**
  - **Descripción**: Nombre del cluster AKS para el ambiente DEV
  - **Tipo**: String
  - **Ejemplo**: `my-aks-cluster-dev`
  - **Sensible**: No (pero recomendado como secret)

- **`AKS_CLUSTER_NAME_STAGE`**
  - **Descripción**: Nombre del cluster AKS para el ambiente STAGE
  - **Tipo**: String
  - **Ejemplo**: `my-aks-cluster-stage`
  - **Sensible**: No (pero recomendado como secret)

- **`AKS_CLUSTER_NAME_PROD`**
  - **Descripción**: Nombre del cluster AKS para el ambiente PROD
  - **Tipo**: String
  - **Ejemplo**: `my-aks-cluster-prod`
  - **Sensible**: No (pero recomendado como secret)

#### 4. `SONARQUBE_DB_PASSWORD` (MUY SENSIBLE)
- **Descripción**: Contraseña para la base de datos PostgreSQL de SonarQube
- **Tipo**: String (contraseña segura)
- **Requisitos**: 
  - Mínimo 8 caracteres
  - Recomendado: usar una contraseña fuerte con mayúsculas, minúsculas, números y caracteres especiales
- **Ejemplo**: `MyStr0ng!P@ssw0rd`
- **Nota**: Esta contraseña se usa en todos los ambientes. Si necesitas contraseñas diferentes por ambiente, considera usar `SONARQUBE_DB_PASSWORD_DEV`, `SONARQUBE_DB_PASSWORD_STAGE`, `SONARQUBE_DB_PASSWORD_PROD`

---

## Azure DevOps Variables

Si estás usando Azure DevOps, configura las siguientes variables en tu Variable Group:

**Configuración:**
1. Ve a Azure DevOps → Pipelines → Library
2. Crea o edita el Variable Group `k8s-config`
3. Agrega las siguientes variables (marca como secret las que sean sensibles)

### Variables del Variable Group `k8s-config`

#### Variables por Ambiente - Resource Groups

- **`resourceGroup_dev`**
  - **Descripción**: Nombre del Resource Group de Azure para el ambiente DEV
  - **Tipo**: Variable normal
  - **Ejemplo**: `my-aks-resource-group-dev`
  - **Secret**: No

- **`resourceGroup_stage`**
  - **Descripción**: Nombre del Resource Group de Azure para el ambiente STAGE
  - **Tipo**: Variable normal
  - **Ejemplo**: `my-aks-resource-group-stage`
  - **Secret**: No

- **`resourceGroup_prod`**
  - **Descripción**: Nombre del Resource Group de Azure para el ambiente PROD
  - **Tipo**: Variable normal
  - **Ejemplo**: `my-aks-resource-group-prod`
  - **Secret**: No

#### Variables por Ambiente - Cluster Names

- **`aksClusterName_dev`**
  - **Descripción**: Nombre del cluster AKS para el ambiente DEV
  - **Tipo**: Variable normal
  - **Ejemplo**: `my-aks-cluster-dev`
  - **Secret**: No

- **`aksClusterName_stage`**
  - **Descripción**: Nombre del cluster AKS para el ambiente STAGE
  - **Tipo**: Variable normal
  - **Ejemplo**: `my-aks-cluster-stage`
  - **Secret**: No

- **`aksClusterName_prod`**
  - **Descripción**: Nombre del cluster AKS para el ambiente PROD
  - **Tipo**: Variable normal
  - **Ejemplo**: `my-aks-cluster-prod`
  - **Secret**: No

### Variables Secretas en Azure DevOps

#### 1. `SONARQUBE_DB_PASSWORD` (MUY SENSIBLE)
- **Descripción**: Contraseña para la base de datos PostgreSQL de SonarQube
- **Tipo**: Variable secreta
- **Cómo configurar**:
  1. Ve a Pipelines → Library
  2. Crea o edita el Variable Group `k8s-config`
  3. Agrega la variable `SONARQUBE_DB_PASSWORD`
  4. **Marca la casilla "Keep this value secret"**
  5. Ingresa el valor de la contraseña
- **Requisitos**: 
  - Mínimo 8 caracteres
  - Recomendado: usar una contraseña fuerte
- **Nota**: Esta contraseña se usa en todos los ambientes. Si necesitas contraseñas diferentes por ambiente, considera usar `SONARQUBE_DB_PASSWORD_DEV`, `SONARQUBE_DB_PASSWORD_STAGE`, `SONARQUBE_DB_PASSWORD_PROD`

### Service Connection en Azure DevOps

#### `Azure-Kubernetes-Service`
- **Descripción**: Service Connection para conectarse a los clusters AKS
- **Tipo**: Azure Resource Manager
- **Cómo configurar**:
  1. Ve a Project Settings → Service connections
  2. New service connection → Azure Resource Manager
  3. Selecciona tu suscripción (debe tener acceso a todos los Resource Groups: dev, stage, prod)
  4. Nombre: `Azure-Kubernetes-Service`
  5. El Service Principal debe tener permisos para acceder a todos los clusters

---

## Resumen de Secrets por Plataforma

### GitHub Actions
| Secret | Sensible | Requerido | Cantidad |
|--------|----------|-----------|----------|
| `AZURE_CREDENTIALS` | Sí | Sí | 1 |
| `AZURE_RESOURCE_GROUP_DEV` | No | Sí | 1 |
| `AZURE_RESOURCE_GROUP_STAGE` | No | Sí | 1 |
| `AZURE_RESOURCE_GROUP_PROD` | No | Sí | 1 |
| `AKS_CLUSTER_NAME_DEV` | No | Sí | 1 |
| `AKS_CLUSTER_NAME_STAGE` | No | Sí | 1 |
| `AKS_CLUSTER_NAME_PROD` | No | Sí | 1 |
| `SONARQUBE_DB_PASSWORD` | **Sí** | Sí | 1 |
| **TOTAL** | | | **8 secrets** |

### Azure DevOps
| Variable | Tipo | Sensible | Requerido | Cantidad |
|----------|------|----------|-----------|----------|
| `resourceGroup_dev` | Variable | No | Sí | 1 |
| `resourceGroup_stage` | Variable | No | Sí | 1 |
| `resourceGroup_prod` | Variable | No | Sí | 1 |
| `aksClusterName_dev` | Variable | No | Sí | 1 |
| `aksClusterName_stage` | Variable | No | Sí | 1 |
| `aksClusterName_prod` | Variable | No | Sí | 1 |
| `SONARQUBE_DB_PASSWORD` | Variable Secreta | **Sí** | Sí | 1 |
| `Azure-Kubernetes-Service` | Service Connection | Sí | Sí | 1 |
| **TOTAL** | | | | **8 variables + 1 service connection** |

---

## Estructura de Ambientes

Cada ambiente es completamente independiente:

```
DEV Environment:
  ├── Resource Group: AZURE_RESOURCE_GROUP_DEV / resourceGroup_dev
  ├── AKS Cluster: AKS_CLUSTER_NAME_DEV / aksClusterName_dev
  └── Namespace: dev

STAGE Environment:
  ├── Resource Group: AZURE_RESOURCE_GROUP_STAGE / resourceGroup_stage
  ├── AKS Cluster: AKS_CLUSTER_NAME_STAGE / aksClusterName_stage
  └── Namespace: stage

PROD Environment:
  ├── Resource Group: AZURE_RESOURCE_GROUP_PROD / resourceGroup_prod
  ├── AKS Cluster: AKS_CLUSTER_NAME_PROD / aksClusterName_prod
  └── Namespace: prod
```

---

## Recomendaciones de Seguridad

1. **Rotación de Contraseñas**: Rota la contraseña `SONARQUBE_DB_PASSWORD` periódicamente (cada 90 días recomendado)

2. **Principio de Mínimo Privilegio**: 
   - El Service Principal de Azure debe tener solo los permisos necesarios
   - Usa roles específicos como "Azure Kubernetes Service Cluster User Role" en lugar de "Contributor"
   - El Service Principal debe tener acceso a los 3 Resource Groups (dev, stage, prod)

3. **Auditoría**: 
   - Revisa regularmente quién tiene acceso a los secrets
   - Habilita logs de auditoría en GitHub/Azure DevOps

4. **Separación por Ambiente**:
   - Considera usar diferentes contraseñas para dev, stage y prod si es necesario
   - Puedes crear secrets específicos por ambiente: `SONARQUBE_DB_PASSWORD_DEV`, `SONARQUBE_DB_PASSWORD_STAGE`, `SONARQUBE_DB_PASSWORD_PROD`

5. **Azure Key Vault** (Recomendado para Producción):
   - Para mayor seguridad, considera usar Azure Key Vault para almacenar los secrets
   - Los pipelines pueden leer los secrets desde Key Vault en tiempo de ejecución

---

## Verificación

Para verificar que los secrets están configurados correctamente:

### GitHub Actions
```bash
# Los secrets no se pueden listar desde la CLI, pero puedes verificar en la UI
# Ve a: Settings → Secrets and variables → Actions
# Debes ver los 8 secrets listados arriba
```

### Azure DevOps
```bash
# Verifica el Variable Group
# Ve a: Pipelines → Library → k8s-config
# Debes ver las 7 variables listadas arriba
```

---

## Troubleshooting

### Error: "Secret not found"
- Verifica que el nombre del secret sea exactamente el mismo (case-sensitive)
- Asegúrate de que el secret esté configurado en el repositorio/organización correcta
- Verifica que estés usando el formato correcto: `AZURE_RESOURCE_GROUP_DEV` (no `AZURE_RESOURCE_GROUP`)

### Error: "Authentication failed"
- Verifica que `AZURE_CREDENTIALS` tenga el formato JSON correcto
- Asegúrate de que el Service Principal tenga los permisos necesarios en los 3 Resource Groups

### Error: "Cannot connect to AKS"
- Verifica que los nombres de Resource Group y Cluster sean correctos para el ambiente seleccionado
- Verifica que el Service Principal tenga acceso al cluster específico del ambiente
- Asegúrate de que estés usando las variables correctas según el ambiente (dev, stage, prod)

### Error: "Variables no configuradas para el ambiente X"
- Verifica que todas las variables por ambiente estén configuradas
- Asegúrate de que los nombres de las variables sigan el patrón: `AZURE_RESOURCE_GROUP_{ENV}` y `AKS_CLUSTER_NAME_{ENV}`
