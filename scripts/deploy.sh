#!/bin/bash
set -eo pipefail

# Function to log messages
log() {
  echo "--- $1"
}

# --- Kubeconfig Setup ---
# The KUBE_CONFIG_DATA environment variable is passed in from the action.
# We decode it and export KUBECONFIG to make it available to Helm.
if [ -z "${KUBE_CONFIG_DATA}" ]; then
  log "🔴 ERROR: KUBE_CONFIG_DATA environment variable is not set."
  exit 1
fi

KUBECONFIG_FILE="/tmp/kubeconfig_$(date +%s)"
echo "${KUBE_CONFIG_DATA}" | base64 -d > "${KUBECONFIG_FILE}"
export KUBECONFIG="${KUBECONFIG_FILE}"
log "✅ Kubeconfig configured successfully for Helm."

# Cleanup trap to remove the temporary kubeconfig file on exit
trap 'rm -f ${KUBECONFIG_FILE}' EXIT

# --- Input Validation ---
# Required inputs from the action's workflow
SERVICE_NAME="${INPUT_SERVICE_NAME:?Service name is required}"
ENVIRONMENT="${INPUT_ENVIRONMENT:?Environment is required}"
HELM_VERSION="${INPUT_HELM_VERSION:?Helm version is required}"
K8S_NAMESPACE="${INPUT_K8S_NAMESPACE:?Kubernetes namespace is required}"
IMAGE_NAME="${INPUT_IMAGE_NAME:?Image name is required}"
ECR_REGISTRY="${INPUT_ECR_REGISTRY:?ECR registry is required}"
DEBUG_ENABLED="${INPUT_DEBUG_ENABLED}"

# --- Helm Deployment ---
# Helm Chart Information
HELM_REPO_URL="https://zimran-tech.github.io/helm-charts"
HELM_REPO_NAME="prosperi-charts"
HELM_CHART_NAME="app"
RELEASE_NAME="${SERVICE_NAME}"

log "🚀 Deploying ${SERVICE_NAME}

# Add Helm repository
log "Adding Helm repository: ${HELM_REPO_URL}"
helm repo add "${HELM_REPO_NAME}" "${HELM_REPO_URL}"
helm repo update

# Construct Helm command
SHARED_VALUES_PATH="${ENVIRONMENT}/shared.yaml"
SERVICE_VALUES_PATH="${ENVIRONMENT}/services/${SERVICE_NAME}.yaml"

# Base Helm command
HELM_COMMAND="helm upgrade --install ${RELEASE_NAME} ${HELM_REPO_NAME}/${HELM_CHART_NAME} \
  --version ${HELM_VERSION} \
  -n ${K8S_NAMESPACE} \
  --set image=${ECR_REGISTRY}/${IMAGE_NAME} \
  --timeout 15m \
  --atomic"

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