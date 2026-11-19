#!/usr/bin/env bash
#
# One-time Google Cloud setup for Taqnyat OTP login. Safe to run again: anything
# that already exists is left alone. Run it in Google Cloud Shell, or anywhere
# gcloud is installed and signed in with Owner access to the project.
#
# Creates:
#   - the `auth-otp` Firestore database
#   - the `otp-auth` service account and its roles
#   - a static outbound IP for the requestOtp function
#
# The last line printed is the IP to add to Taqnyat's allowlist.

set -euo pipefail

PROJECT="worker-app-tnext"
REGION="europe-west1"
DATABASE="auth-otp"
DATABASE_LOCATION="eur3"
SERVICE_ACCOUNT="otp-auth@${PROJECT}.iam.gserviceaccount.com"

NETWORK="otp-egress-net"
SUBNET="otp-egress-subnet"
SUBNET_RANGE="10.124.0.0/28"
CONNECTOR="otp-egress"
ROUTER="otp-egress-router"
NAT="otp-egress-nat"
STATIC_IP="otp-egress-ip"

# Runs the create command only when the describe command finds nothing.
ensure() {
  local label="$1" describe="$2" create="$3"
  if eval "${describe}" >/dev/null 2>&1; then
    echo "exists:  ${label}"
  else
    echo "create:  ${label}"
    eval "${create}"
  fi
}

gcloud config set project "${PROJECT}" >/dev/null

echo "== Enabling APIs"
gcloud services enable \
  compute.googleapis.com \
  vpcaccess.googleapis.com \
  firestore.googleapis.com \
  secretmanager.googleapis.com \
  --project="${PROJECT}"

echo "== OTP database"
ensure "database ${DATABASE}" \
  "gcloud firestore databases describe --database=${DATABASE} --project=${PROJECT}" \
  "gcloud firestore databases create --database=${DATABASE} --location=${DATABASE_LOCATION} --delete-protection --project=${PROJECT}"

echo "== Service account"
ensure "service account otp-auth" \
  "gcloud iam service-accounts describe ${SERVICE_ACCOUNT} --project=${PROJECT}" \
  "gcloud iam service-accounts create otp-auth --display-name='OTP login functions' --project=${PROJECT} && sleep 15"

for role in \
  roles/datastore.user \
  roles/firebaseauth.admin \
  roles/secretmanager.secretAccessor \
  roles/logging.logWriter \
  roles/run.invoker; do
  gcloud projects add-iam-policy-binding "${PROJECT}" \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="${role}" \
    --condition=None \
    --quiet >/dev/null
  echo "granted: ${role}"
done

# Lets the functions sign Firebase custom tokens as themselves.
gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT}" \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project="${PROJECT}" \
  --quiet >/dev/null
echo "granted: roles/iam.serviceAccountTokenCreator on itself"

echo "== Static outbound IP"
ensure "network ${NETWORK}" \
  "gcloud compute networks describe ${NETWORK} --project=${PROJECT}" \
  "gcloud compute networks create ${NETWORK} --subnet-mode=custom --project=${PROJECT}"

ensure "subnet ${SUBNET}" \
  "gcloud compute networks subnets describe ${SUBNET} --region=${REGION} --project=${PROJECT}" \
  "gcloud compute networks subnets create ${SUBNET} --network=${NETWORK} --range=${SUBNET_RANGE} --region=${REGION} --project=${PROJECT}"

ensure "connector ${CONNECTOR}" \
  "gcloud compute networks vpc-access connectors describe ${CONNECTOR} --region=${REGION} --project=${PROJECT}" \
  "gcloud compute networks vpc-access connectors create ${CONNECTOR} --subnet=${SUBNET} --subnet-project=${PROJECT} --region=${REGION} --machine-type=e2-micro --min-instances=2 --max-instances=3 --project=${PROJECT}"

ensure "static IP ${STATIC_IP}" \
  "gcloud compute addresses describe ${STATIC_IP} --region=${REGION} --project=${PROJECT}" \
  "gcloud compute addresses create ${STATIC_IP} --region=${REGION} --project=${PROJECT}"

ensure "router ${ROUTER}" \
  "gcloud compute routers describe ${ROUTER} --region=${REGION} --project=${PROJECT}" \
  "gcloud compute routers create ${ROUTER} --network=${NETWORK} --region=${REGION} --project=${PROJECT}"

ensure "NAT ${NAT}" \
  "gcloud compute routers nats describe ${NAT} --router=${ROUTER} --region=${REGION} --project=${PROJECT}" \
  "gcloud compute routers nats create ${NAT} --router=${ROUTER} --region=${REGION} --nat-custom-subnet-ip-ranges=${SUBNET} --nat-external-ip-pool=${STATIC_IP} --project=${PROJECT}"

echo
echo "Done. Add this IP to the Taqnyat API allowlist:"
gcloud compute addresses describe "${STATIC_IP}" \
  --region="${REGION}" \
  --project="${PROJECT}" \
  --format="value(address)"
