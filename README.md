# Stack de Monitoreo y Observabilidad en AKS

Este repositorio contiene los manifests de Kubernetes y workflows de GitHub Actions necesarios para desplegar un stack completo de monitoreo y observabilidad en un clúster de Azure Kubernetes Service (AKS).

## Componentes del Stack

### Monitoreo (Prometheus + Grafana)
- **Prometheus**: Recolección y almacenamiento de métricas
- **Grafana**: Visualización de métricas y dashboards
- **AlertManager**: Gestión y enrutamiento de alertas

### Logging (ELK Stack)
- **Elasticsearch**: Almacenamiento de logs
- **Logstash**: Procesamiento y transformación de logs
- **Kibana**: Visualización y análisis de logs

### Tracing
- **Zipkin**: Trazabilidad distribuida (ya implementado)

## Estructura del Proyecto

```
.
├── k8s/
│   ├── prometheus/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   └── alert-rules.yaml
│   ├── grafana/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap-datasources.yaml
│   │   ├── configmap-dashboards.yaml
│   │   └── configmap-dashboard-definitions.yaml
│   ├── elasticsearch/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── logstash/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── kibana/
│   │   └── deployment.yaml (incluye service)
│   ├── alertmanager/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── zipkin/
│       ├── deployment.yaml
│       └── service.yaml
├── .github/workflows/
│   ├── monitoring-deploy.yml
│   └── zipkin-deploy.yml
├── SECRETS.md
└── README.md
```

## Requisitos Previos

1. **Repositorio conectado a AKS**
   - Debes tener un Service Principal con permisos sobre los tres clusters (dev, stage, prod).

2. **Secrets Configurados**
   - **GitHub Secrets**: Solo necesitas `AZURE_CREDENTIALS` (Service Principal)
   - **Azure Key Vault**: Los demás secrets (Resource Groups y Cluster Names) se leen automáticamente del Key Vault
   - Consulta [SECRETS.md](SECRETS.md) para la configuración completa

3. **Cluster preparado**
   - AKS debe contar con recursos suficientes para el stack de monitoreo
   - Almacenamiento efímero (puede migrarse a persistente después)

## Workflows de GitHub Actions

### 1. Monitoring Stack Deployment (`monitoring-deploy.yml`)

Despliega todo el stack de monitoreo (Prometheus, Grafana, ELK, AlertManager).

- **Trigger**: Manual (`workflow_dispatch`)
- **Parámetro**: `environment` con opciones: `dev`, `stage`, `prod` o `all`
- **Acciones**:
  1. Inicia sesión en Azure
  2. Obtiene secrets del Key Vault
  3. Conecta al cluster AKS
  4. Crea/actualiza namespace
  5. Despliega todos los componentes del stack
  6. Verifica el estado de los deployments

### 2. Zipkin Deployment (`zipkin-deploy.yml`)

Despliega solo Zipkin para distributed tracing.

- **Trigger**: Manual (`workflow_dispatch`)
- **Parámetro**: `environment` con opciones: `dev`, `stage`, `prod` o `all`

## Ambientes y Namespaces

| Ambiente | Namespace |
|----------|-----------|
| dev      | `dev`     |
| stage    | `stage`   |
| prod     | `prod`    |

Cuando eliges la opción `all`, el workflow itera en ese orden: dev → stage → prod.

## Componentes del Stack

### Prometheus

- **Puerto**: 9090
- **Recursos**: 512Mi-2Gi RAM, 250m-1000m CPU
- **Funciones**:
  - Scraping de métricas de todos los microservicios
  - Almacenamiento de métricas (15 días de retención)
  - Evaluación de reglas de alertas
- **Acceso**: `http://prometheus.<namespace>:9090`

### Grafana

- **Puerto**: 3000
- **Recursos**: 256Mi-512Mi RAM, 100m-500m CPU
- **Credenciales por defecto**: `admin/admin`
- **Dashboards incluidos**:
  - System Overview: Métricas generales del sistema
  - Business Metrics: Métricas de negocio (ventas, pedidos, usuarios, etc.)
  - Resilience Metrics: Circuit breakers, retries, bulkheads
  - Service Details: Métricas detalladas por servicio
- **Acceso**: `http://grafana.<namespace>:3000`

### Elasticsearch

- **Puerto**: 9200 (HTTP), 9300 (Transport)
- **Recursos**: 1Gi-2Gi RAM, 500m-1000m CPU
- **Almacenamiento**: Efímero (emptyDir)
- **Funciones**: Almacenamiento de logs indexados
- **Acceso**: `http://elasticsearch.<namespace>:9200`

### Logstash

- **Puerto**: 5044 (Beats), 9600 (Monitoring)
- **Recursos**: 512Mi-1Gi RAM, 250m-500m CPU
- **Funciones**: Procesamiento y transformación de logs antes de enviarlos a Elasticsearch
- **Acceso**: `http://logstash.<namespace>:5044`

### Kibana

- **Puerto**: 5601
- **Recursos**: 512Mi-1Gi RAM, 250m-500m CPU
- **Funciones**: Visualización y análisis de logs
- **Acceso**: `http://kibana.<namespace>:5601`

### AlertManager

- **Puerto**: 9093
- **Recursos**: 128Mi-256Mi RAM, 100m-200m CPU
- **Funciones**: Gestión y enrutamiento de alertas desde Prometheus
- **Acceso**: `http://alertmanager.<namespace>:9093`

### Zipkin

- **Puerto**: 9411
- **Recursos**: 64Mi-128Mi RAM, 50m-100m CPU
- **Funciones**: Distributed tracing
- **Acceso**: `http://zipkin.<namespace>:9411`

## Recursos Totales Necesarios (Optimizados para DEV)

| Componente | CPU (request/limit) | RAM (request/limit) |
|------------|---------------------|---------------------|
| Prometheus | 100m / 200m         | 128Mi / 256Mi       |
| Grafana    | 50m / 100m          | 64Mi / 128Mi        |
| Elasticsearch | 100m / 200m      | 192Mi / 256Mi        |
| Logstash   | 50m / 100m          | 128Mi / 192Mi       |
| Kibana     | 50m / 100m          | 128Mi / 192Mi       |
| AlertManager | 50m / 100m         | 32Mi / 64Mi         |
| Zipkin     | 50m / 100m          | 64Mi / 128Mi         |
| **Total**  | **450m / 900m**     | **744Mi / 1.2Gi**   |

> **Nota**: Estos recursos están optimizados para entornos de desarrollo. Para producción, se recomienda aumentar los recursos según la carga esperada.

## Configuración de Métricas en Microservicios

Todos los microservicios deben tener habilitado el endpoint de Prometheus:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,metrics
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
      environment: ${spring.profiles.active}
```

Los servicios configurados para scraping en Prometheus:
- service-discovery (8761)
- cloud-config (9296)
- api-gateway (8080)
- proxy-client (8900)
- user-service (8700)
- product-service (8500)
- order-service (8600)
- payment-service (8800)
- shipping-service (8400)
- favourite-service (8300)

## Alertas Configuradas

### Infraestructura
- Pods en CrashLoopBackOff
- Alto uso de CPU (>80%)
- Alto uso de memoria (>90%)

### Aplicación
- Alta tasa de errores HTTP (>5%)
- Alta latencia (p95 > 2 segundos)
- Circuit breaker abierto
- Health check fallando

### Negocio
- Alta tasa de abandono de carritos (>50%)
- Alta tasa de fallo de pagos (>10%)
- Caída en ventas (>20% comparado con período anterior)

## Dashboards de Grafana

### System Overview
- CPU y memoria por servicio
- Tasa de requests HTTP
- Pods activos
- Tasa de errores general

### Business Metrics
- Total de ventas
- Pedidos (creados, completados, cancelados)
- Usuarios activos
- Productos vendidos
- Tasa de éxito de pagos
- Tasa de conversión de carritos
- Tasa de abandono de carritos

### Resilience Metrics
- Estado de circuit breakers
- Tasa de fallos de circuit breakers
- Intentos de retry
- Llamadas concurrentes disponibles (bulkhead)

### Service Details
- Tasa de requests por servicio
- Tiempo de respuesta (p95)
- Tasa de errores por servicio
- Uso de memoria JVM

## Acceso a los Servicios

Todos los servicios usan `ClusterIP` (acceso interno). Para acceder desde dentro del cluster:

- **Mismo namespace**: `http://<service-name>:<port>`
- **Distinto namespace**: `http://<service-name>.<namespace>:<port>`
- **FQDN completo**: `http://<service-name>.<namespace>.svc.cluster.local:<port>`

Para exponer servicios externamente, puedes:
1. Cambiar el tipo de servicio a `LoadBalancer`
2. Crear un Ingress con autenticación

## Envío de Logs a Logstash

Los microservicios pueden enviar logs a Logstash usando HTTP:

```yaml
logging:
  appender:
    logstash:
      url: http://logstash:5044
      encoder:
        class: net.logstash.logback.encoder.LogstashEncoder
```

O usando Filebeat/Fluentd para recolectar logs de los pods.

## Troubleshooting

### Verificar estado de los deployments

```bash
# Ver todos los pods del stack de monitoreo
kubectl get pods -n <namespace> -l component=monitoring
kubectl get pods -n <namespace> -l component=logging

# Ver logs de un componente
kubectl logs deployment/prometheus -n <namespace>
kubectl logs deployment/grafana -n <namespace>
kubectl logs deployment/elasticsearch -n <namespace>
```

### Verificar servicios

```bash
# Ver servicios
kubectl get svc -n <namespace> -l component=monitoring
kubectl get svc -n <namespace> -l component=logging

# Ver endpoints
kubectl get endpoints -n <namespace>
```

### Verificar métricas en Prometheus

```bash
# Port-forward para acceso local
kubectl port-forward svc/prometheus 9090:9090 -n <namespace>

# Acceder a http://localhost:9090
```

### Verificar dashboards en Grafana

```bash
# Port-forward para acceso local
kubectl port-forward svc/grafana 3000:3000 -n <namespace>

# Acceder a http://localhost:3000 (admin/admin)
```

### Problemas comunes

1. **Prometheus no puede hacer scraping**
   - Verificar que los servicios tengan el endpoint `/actuator/prometheus` habilitado
   - Verificar que los servicios estén accesibles desde Prometheus
   - Revisar logs de Prometheus: `kubectl logs deployment/prometheus -n <namespace>`

2. **Elasticsearch no inicia**
   - Verificar recursos disponibles en el cluster
   - Revisar logs: `kubectl logs deployment/elasticsearch -n <namespace>`
   - Verificar que no haya conflictos de puertos

3. **Grafana no muestra dashboards**
   - Verificar que el ConfigMap de dashboards esté montado correctamente
   - Verificar que Prometheus esté configurado como datasource
   - Revisar logs: `kubectl logs deployment/grafana -n <namespace>`

## Notas Importantes

1. **Idempotencia**: Puedes ejecutar los workflows cuantas veces quieras. Usan `kubectl apply`, por lo que actualizan sin conflictos.

2. **Namespaces**: Los crea si no existen. Si ya están presentes, simplemente los reutiliza.

3. **Almacenamiento**: Actualmente usa almacenamiento efímero. Para producción, considera migrar a PersistentVolumes.

4. **Seguridad**: Todos los servicios usan `ClusterIP` por defecto. Para producción, considera:
   - Autenticación en Grafana y Kibana
   - TLS/SSL para comunicación entre servicios
   - Network Policies para restringir acceso

5. **Escalabilidad**: Para ambientes de producción con alta carga, considera:
   - Aumentar réplicas de Prometheus
   - Usar Elasticsearch en modo cluster
   - Implementar sharding de logs

## Próximos Pasos

- [ ] Implementar métricas de negocio personalizadas en los microservicios
- [ ] Configurar notificaciones de alertas (email, Slack, etc.)
- [ ] Migrar a almacenamiento persistente para producción
- [ ] Implementar autenticación en Grafana y Kibana
- [ ] Configurar Network Policies
- [ ] Optimizar health checks en todos los deployments
