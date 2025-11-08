#!/bin/bash

# Script helper para desplegar aplicaciones localmente usando kubectl
# Uso: ./scripts/deploy.sh <app> <environment>
# Ejemplo: ./scripts/deploy.sh zipkin dev
#          SONARQUBE_DB_PASSWORD="mypassword" ./scripts/deploy.sh sonarqube all
#
# NOTA: Para SonarQube, debes configurar la variable de entorno SONARQUBE_DB_PASSWORD

set -e

APP=$1
ENVIRONMENT=$2

if [ -z "$APP" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Uso: $0 <app> <environment>"
    echo "Apps disponibles: zipkin, sonarqube, all"
    echo "Ambientes disponibles: dev, stage, prod, all"
    exit 1
fi

# Función para desplegar Zipkin
deploy_zipkin() {
    local env=$1
    echo "Desplegando Zipkin en ambiente: $env"
    
    kubectl create namespace $env --dry-run=client -o yaml | kubectl apply -f -
    
    export NAMESPACE=$env
    envsubst < k8s/zipkin/deployment.yaml | kubectl apply -f -
    envsubst < k8s/zipkin/service.yaml | kubectl apply -f -
    
    echo "Esperando a que Zipkin esté listo..."
    kubectl rollout status deployment/zipkin -n $env --timeout=300s
    echo "Zipkin desplegado exitosamente en $env"
}

# Función para desplegar SonarQube
deploy_sonarqube() {
    local env=$1
    echo "Desplegando SonarQube en ambiente: $env"
    
    if [ -z "$SONARQUBE_DB_PASSWORD" ]; then
        echo "ERROR: La variable SONARQUBE_DB_PASSWORD no está configurada"
        echo "Configúrala como variable de entorno antes de ejecutar el script"
        exit 1
    fi
    
    kubectl create namespace $env --dry-run=client -o yaml | kubectl apply -f -
    
    export NAMESPACE=$env
    export SONARQUBE_DB_PASSWORD="${SONARQUBE_DB_PASSWORD}"
    envsubst < k8s/sonarqube/secret.yaml | kubectl apply -f -
    envsubst < k8s/sonarqube/pvc.yaml | kubectl apply -f -
    envsubst < k8s/sonarqube/postgres-deployment.yaml | kubectl apply -f -
    
    # Esperar a que los PVCs estén bound
    echo "Esperando a que los PVCs estén aprovisionados..."
    kubectl wait --for=condition=bound pvc/sonarqube-data-pvc -n $env --timeout=120s || true
    kubectl wait --for=condition=bound pvc/sonarqube-extensions-pvc -n $env --timeout=120s || true
    kubectl wait --for=condition=bound pvc/sonarqube-logs-pvc -n $env --timeout=120s || true
    kubectl wait --for=condition=bound pvc/sonarqube-db-pvc -n $env --timeout=120s || true
    
    echo "Esperando a que la base de datos esté lista..."
    kubectl wait --for=condition=ready pod -l app=sonarqube-db -n $env --timeout=600s || {
      echo "ERROR: El pod de la base de datos no está listo. Diagnóstico:"
      kubectl get pods -l app=sonarqube-db -n $env
      kubectl get pvc -n $env
      kubectl describe pod -l app=sonarqube-db -n $env
      POD_NAME=$(kubectl get pods -l app=sonarqube-db -n $env -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
      if [ -n "$POD_NAME" ]; then
        echo "Logs del pod $POD_NAME:"
        kubectl logs $POD_NAME -n $env --tail=50
      fi
      exit 1
    }
    
    envsubst < k8s/sonarqube/deployment.yaml | kubectl apply -f -
    envsubst < k8s/sonarqube/service.yaml | kubectl apply -f -
    
    echo "Esperando a que SonarQube esté listo..."
    kubectl rollout status deployment/sonarqube -n $env --timeout=600s
    echo "SonarQube desplegado exitosamente en $env"
}

# Determinar ambientes
if [ "$ENVIRONMENT" = "all" ]; then
    ENVIRONMENTS="dev stage prod"
else
    ENVIRONMENTS=$ENVIRONMENT
fi

# Desplegar según la app
for env in $ENVIRONMENTS; do
    case $APP in
        zipkin)
            deploy_zipkin $env
            ;;
        sonarqube)
            deploy_sonarqube $env
            ;;
        all)
            deploy_zipkin $env
            deploy_sonarqube $env
            ;;
        *)
            echo "App no reconocida: $APP"
            echo "Apps disponibles: zipkin, sonarqube, all"
            exit 1
            ;;
    esac
done

echo "Despliegue completado!"

