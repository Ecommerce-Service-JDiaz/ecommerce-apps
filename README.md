# Zipkin en AKS

Este repositorio contiene los manifests de Kubernetes y el workflow de GitHub Actions necesarios para desplegar Zipkin en un clúster de Azure Kubernetes Service (AKS).

## Estructura del Proyecto

```
.
├── k8s/
│   └── zipkin/
│       ├── deployment.yaml
│       └── service.yaml
├── .github/workflows/
│   └── zipkin-deploy.yml
├── SECRETS.md
└── README.md
```

## Requisitos Previos

1. **Repositorio conectado a AKS**
   - Debes tener un Service Principal con permisos sobre los tres clusters (dev, stage, prod).

2. **Secrets Configurados**
   - **GitHub Secrets**: Solo necesitas `AZURE_CREDENTIALS` (Service Principal)
   - **Azure Key Vault**: Los demás secrets (Resource Groups y Cluster Names) se leen automáticamente del Key Vault en el Resource Group `ecommerce-rg-global`
   - El pipeline detecta dinámicamente el Key Vault (el único en ese Resource Group), por lo que funciona incluso si el nombre cambia después de un rollback
   - Consulta [SECRETS.md](SECRETS.md) para la configuración completa

3. **Cluster preparado**
   - AKS debe contar con un `StorageClass` por defecto (Zipkin usa almacenamiento en memoria, pero el cluster se usa para más servicios).

## Workflow: `.github/workflows/zipkin-deploy.yml`

- Trigger manual (`workflow_dispatch`).
- Parámetro `environment` con las opciones: `dev`, `stage`, `prod` o `all`.
- Acciones que realiza:
  1. Inicia sesión en Azure usando `AZURE_CREDENTIALS` de GitHub Secrets
  2. Detecta dinámicamente el Key Vault en el Resource Group `ecommerce-rg-global`
  3. Lee los secrets del Azure Key Vault: Resource Groups y Cluster Names
  4. Obtiene las credenciales del cluster correspondiente según el ambiente
  5. Crea/actualiza el namespace (`dev`, `stage`, `prod`)
  6. Aplica los manifests de Zipkin (`deployment` y `service`)
  7. Espera el rollout del deployment
  8. Lista pods y endpoints del servicio
  9. Muestra la URL interna para consumir Zipkin dentro del cluster

### Cómo ejecutarlo

1. GitHub → Actions → `zipkin-deploy`
2. `Run workflow`
3. Selecciona el ambiente y ejecuta.

## Ambientes y Namespaces

| Ambiente | Namespace |
|----------|-----------|
| dev      | `dev`     |
| stage    | `stage`   |
| prod     | `prod`    |

Cuando eliges la opción `all`, el workflow itera en ese orden: dev → stage → prod.

## Manifests de Zipkin

- `k8s/zipkin/deployment.yaml`
  - Imagen: `openzipkin/zipkin:latest`
  - Requests/Limits: 250m CPU / 512Mi RAM (request), 500m CPU / 1Gi RAM (limit)
  - Readiness & Liveness probes: `GET /health`

- `k8s/zipkin/service.yaml`
  - Tipo: `ClusterIP`
  - Puerto: `9411`
  - Proporciona un DNS interno: `zipkin.<namespace>.svc.cluster.local`

## Acceso Interno

Zipkin **no** expone IP pública. Un microservicio dentro del cluster puede usar la URL:

- Mismo namespace: `http://zipkin:9411`
- Distinto namespace (ej. ambiente dev): `http://zipkin.dev:9411`
- FQDN completo: `http://zipkin.dev.svc.cluster.local:9411`

El workflow mostrará estos detalles al finalizar el despliegue.

## Recursos Necesarios

| Recurso | CPU (request/limit) | RAM (request/limit) |
|---------|---------------------|---------------------|
| Zipkin  | 250m / 500m         | 512Mi / 1Gi         |

## Notas Importantes

1. **Idempotencia**: Puedes ejecutar el workflow cuantas veces quieras. Usa `kubectl apply`, por lo que actualiza sin conflictos.
2. **Namespaces**: Los crea si no existen. Si ya están presentes, simplemente los reutiliza.
3. **Acceso**: Al ser `ClusterIP`, solo es accesible desde dentro del cluster. Para exponerlo externamente tendrías que crear un Ingress o cambiar el tipo de servicio.
4. **Tracing**: Configura tus microservicios para enviar trazas a `http://zipkin.<namespace>:9411`.

## Troubleshooting

```bash
# Ver pods
kubectl get pods -n <namespace>

# Logs de Zipkin
a) kubectl logs deployment/zipkin -n <namespace>

# Detalles del servicio (ClusterIP)
kubectl get svc zipkin -n <namespace>

# Endpoints registrados
a) kubectl get endpoints zipkin -n <namespace>
```

Si el rollout falla, revisa `kubectl describe pod -l app=zipkin -n <namespace>` para ver eventos y errores.

