#!/bin/bash

set -e

if [[ -z ${RECAPTCHA_KEY} ]]; then
  echo "Must have RECAPTCHA_KEY environment variable set"
  exit
fi

if [[ -z ${GOOGLE_FORM_URL} ]]; then
  echo "Must have GOOGLE_FORM_URL environment variable set"
  exit
fi

gcloud functions deploy contact_form_function --gen2 --runtime=python312 \
  --region=europe-north1 --source=. --entry-point=contact_form --trigger-http \
  --allow-unauthenticated \
  --set-env-vars RECAPTCHA_KEY=${RECAPTCHA_KEY},GOOGLE_FORM_URL=${GOOGLE_FORM_URL}