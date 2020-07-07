#!/bin/sh

if [ -f opa-config.yml ]
  then
    echo "file opa-config.yml already exists"
  else
    touch opa-config.yml
fi



cat > opa-config.yml  << EOF
services:
  appsmith:
    url: ${APPSMITH_SERVER_URL}
    credentials:
      basic:
        token: "YXBpX3VzZXI6OHVBQDsmbUI6Y252Tn57Iw=="

labels:
  app: appsmith-docker
  region: east
  environment: docker

bundles:
  authz:
    service: appsmith
    resource: bundle.tar.gz
    polling:
      min_delay_seconds: 60
      max_delay_seconds: 120



EOF
