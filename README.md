# Ecommerce Apps - Kubernetes Deployment

Este repositorio contiene las definiciones de Kubernetes y pipelines de Azure DevOps para desplegar aplicaciones en Azure Kubernetes Service (AKS).

## Aplicaciones

- **Zipkin**: Sistema de trazabilidad distribuida
- **SonarQube**: Plataforma de análisis de calidad de código

## Estructura del Proyecto

```
.
├── k8s/                    # Manifests de Kubernetes
│   ├── zipkin/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── sonarqube/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── pvc.yaml
│       ├── secret.yaml
│       └── postgres-deployment.yaml
├── pipelines/              # Pipelines de Azure DevOps
│   ├── zipkin-deploy.yml
│   ├── sonarqube-deploy.yml
│   └── deploy-all.yml
├── .github/workflows/      # Pipelines de GitHub Actions
│   ├── zipkin-deploy.yml
│   ├── sonarqube-deploy.yml
│   └── deploy-all.yml
├── scripts/                # Scripts de ayuda
│   └── deploy.sh
├── SECRETS.md              # Documentación de variables secretas
└── README.md
```

## Configuración Previa

### 1. Variables Secretas

**IMPORTANTE**: Todas las credenciales y contraseñas deben configurarse como variables secretas. **NO** deben estar hardcodeadas en los archivos.

Consulta el archivo [SECRETS.md](SECRETS.md) para ver el listado completo de variables secretas requeridas según la plataforma que uses:

- **GitHub Actions**: Configura los secrets en Settings → Secrets and variables → Actions
- **Azure DevOps**: Configura las variables en Pipelines → Library (Variable Group `k8s-config`)

### 2. Variables Secretas Requeridas

**IMPORTANTE**: Cada ambiente (dev, stage, prod) tiene su propio Resource Group y cluster de Kubernetes, por lo que se requieren variables separadas para cada uno.

#### Para GitHub Actions (8 secrets):
- `AZURE_CREDENTIALS` - Credenciales de Azure (Service Principal JSON)
- `AZURE_RESOURCE_GROUP_DEV` - Resource Group para DEV
- `AZURE_RESOURCE_GROUP_STAGE` - Resource Group para STAGE
- `AZURE_RESOURCE_GROUP_PROD` - Resource Group para PROD
- `AKS_CLUSTER_NAME_DEV` - Cluster AKS para DEV
- `AKS_CLUSTER_NAME_STAGE` - Cluster AKS para STAGE
- `AKS_CLUSTER_NAME_PROD` - Cluster AKS para PROD
- `SONARQUBE_DB_PASSWORD` - Contraseña de la base de datos PostgreSQL

#### Para Azure DevOps (7 variables + 1 service connection):
- Variable Group `k8s-config`:
  - `resourceGroup_dev` - Resource Group para DEV
  - `resourceGroup_stage` - Resource Group para STAGE
  - `resourceGroup_prod` - Resource Group para PROD
  - `aksClusterName_dev` - Cluster AKS para DEV
  - `aksClusterName_stage` - Cluster AKS para STAGE
  - `aksClusterName_prod` - Cluster AKS para PROD
  - `SONARQUBE_DB_PASSWORD` (como variable secreta) - Contraseña de la base de datos
- Service Connection: `Azure-Kubernetes-Service`

Ver [SECRETS.md](SECRETS.md) para instrucciones detalladas y el listado completo.

## Pipelines

Este proyecto incluye pipelines para dos plataformas:

### Azure DevOps Pipelines (`pipelines/`)

Pipelines YAML para Azure DevOps con triggers manuales.

#### Pipeline: zipkin-deploy.yml
- Despliega únicamente Zipkin
- **Uso**: Azure DevOps → Pipelines → Ejecutar manualmente → Seleccionar ambiente

#### Pipeline: sonarqube-deploy.yml
- Despliega únicamente SonarQube (incluye PostgreSQL)
- **Uso**: Azure DevOps → Pipelines → Ejecutar manualmente → Seleccionar ambiente

#### Pipeline: deploy-all.yml
- Despliega todas las aplicaciones (Zipkin y SonarQube)
- **Uso**: Azure DevOps → Pipelines → Ejecutar manualmente → Seleccionar ambiente

### GitHub Actions Workflows (`.github/workflows/`)

Workflows para GitHub Actions con triggers manuales (workflow_dispatch).

#### Workflow: zipkin-deploy.yml
- Despliega únicamente Zipkin
- **Uso**: GitHub → Actions → Seleccionar workflow → Run workflow → Seleccionar ambiente

#### Workflow: sonarqube-deploy.yml
- Despliega únicamente SonarQube (incluye PostgreSQL)
- **Uso**: GitHub → Actions → Seleccionar workflow → Run workflow → Seleccionar ambiente

#### Workflow: deploy-all.yml
- Despliega todas las aplicaciones (Zipkin y SonarQube)
- **Uso**: GitHub → Actions → Seleccionar workflow → Run workflow → Seleccionar ambiente

**Parámetros disponibles en todos los pipelines:**
- `environment`: Ambiente de despliegue (dev, stage, prod, all)

## Ambientes

Los pipelines soportan 4 opciones de despliegue:

- **dev**: Despliega solo en el ambiente de desarrollo
- **stage**: Despliega solo en el ambiente de staging
- **prod**: Despliega solo en el ambiente de producción
- **all**: Despliega en los tres ambientes (dev, stage, prod)

Cada ambiente utiliza un namespace diferente en Kubernetes:
- `dev`
- `stage`
- `prod`

## Acceso a las Aplicaciones

### Zipkin

- **Puerto**: 9411
- **Health Check**: `/health`
- **Acceso**: A través del servicio ClusterIP `zipkin` en el namespace correspondiente

### SonarQube

- **Puerto**: 9000
- **Health Check**: `/api/system/status`
- **Acceso**: A través del servicio ClusterIP `sonarqube` en el namespace correspondiente
- **Credenciales por defecto**: admin/admin (cambiar en el primer acceso)

## Recursos Requeridos

### Zipkin
- CPU: 250m (request) / 500m (limit)
- Memoria: 512Mi (request) / 1Gi (limit)

### SonarQube
- CPU: 1000m (request) / 2000m (limit)
- Memoria: 2Gi (request) / 4Gi (limit)
- Almacenamiento: 35Gi total (20Gi datos + 10Gi extensiones + 5Gi logs)

### PostgreSQL (SonarQube)
- CPU: 250m (request) / 500m (limit)
- Memoria: 512Mi (request) / 1Gi (limit)
- Almacenamiento: 10Gi

## Notas Importantes

1. **Secrets**: La contraseña de la base de datos está hardcodeada en `secret.yaml`. Para producción, se recomienda usar Azure Key Vault.

2. **Storage**: SonarQube requiere PersistentVolumeClaims. Asegúrate de que tu cluster de AKS tenga un StorageClass configurado.

3. **Red**: Los servicios están configurados como ClusterIP. Si necesitas acceso externo, considera usar Ingress o LoadBalancer.

4. **Escalabilidad**: Las aplicaciones están configuradas con 1 réplica. Ajusta según tus necesidades.

## Troubleshooting

### Verificar el estado de los pods

```bash
kubectl get pods -n <namespace>
```

### Ver logs de una aplicación

```bash
# Zipkin
kubectl logs -f deployment/zipkin -n <namespace>

# SonarQube
kubectl logs -f deployment/sonarqube -n <namespace>
```

### Verificar servicios

```bash
kubectl get svc -n <namespace>
```

### Reiniciar un deployment

```bash
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```

