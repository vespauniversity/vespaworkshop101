#!/bin/sh

# Simple example of calling Vespa Cloud /search with curl and mTLS.
# Adjust VESPA_URL, CERT, and KEY to match your environment.

VESPA_URL="https://e96adef2.c6re5c39.z.vespa-app.cloud"
CERT="/home/user/.vespa/my-tenant.ecommerce-app.default/data-plane-public-cert.pem"
KEY="/home/user/.vespa/my-tenant.ecommerce-app.default/data-plane-private-key.pem"

curl --cert "$CERT" \
     --key "$KEY" \
     -H "Content-Type: application/json" \
     -d '{
  "yql": "select * from product where Gender contains \"women\""
}' \
     "$VESPA_URL/search/"
