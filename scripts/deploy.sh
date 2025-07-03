#!/bin/bash
set -eo pipefail

# Required inputs
SERVICE_NAME="${INPUT_SERVICE_NAME}"
ENVIRONMENT="${INPUT_ENVIRONMENT}"
HELM_VERSION="${INPUT_HELM_VERSION}"
K8S_NAMESPACE="${INPUT_K8S_NAMESPACE}"
IMAGE_NAME="${INPUT_IMAGE_NAME}"
ECR_REGISTRY="${INPUT_ECR_REGISTRY}"
DEBUG_ENABLED="${INPUT_DEBUG_ENABLED}"

# Helm Chart Information
HELM_REPO_URL="https://zimran-tech.github.io/helm-charts"
HELM_CHART_NAME="app"
HELM_REPO_NAME="prosperi-charts"

# Function to log messages
log() {
  echo "--- $1"
}

# Add Helm repository
log "Adding Helm repository: ${HELM_REPO_URL}"
helm repo add "${HELM_REPO_NAME}" "${HELM_REPO_URL}"
helm repo update

# Construct Helm command
SHARED_VALUES_PATH="./${ENVIRONMENT}/shared.yaml"
SERVICE_VALUES_PATH="./${ENVIRONMENT}/services/${SERVICE_NAME}.yaml"

HELM_COMMAND="helm upgrade --install ${SERVICE_NAME} ${HELM_REPO_NAME}/${HELM_CHART_NAME} \
  --version ${HELM_VERSION} \
  -n ${K8S_NAMESPACE} \
  --set image=${ECR_REGISTRY}/${IMAGE_NAME} \
  --atomic \
  --timeout 15m"

if [[ "${DEBUG_ENABLED}" == "true" ]]; then
  HELM_COMMAND="${HELM_COMMAND} --debug"
fi

# Include shared values file if it exists
if [ -f "$SHARED_VALUES_PATH" ]; then
  HELM_COMMAND="${HELM_COMMAND} -f $SHARED_VALUES_PATH"
  log "✅ Included shared values file: $SHARED_VALUES_PATH"
else
  log "🟡 Shared values file not found, skipping: $SHARED_VALUES_PATH"
fi

# Include service-specific values file if it exists
if [ -f "$SERVICE_VALUES_PATH" ]; then
  HELM_COMMAND="${HELM_COMMAND} -f $SERVICE_VALUES_PATH"
  log "✅ Included service-specific values file: $SERVICE_VALUES_PATH"
else
  log "🟡 Service-specific values file not found, skipping: $SERVICE_VALUES_PATH"
fi

# Execute Helm command
log "Executing Helm command..."
echo "${HELM_COMMAND}"
eval "${HELM_COMMAND}"

log "🎉 Deployment of ${SERVICE_NAME} to ${ENVIRONMENT} completed successfully." 