#!/bin/sh

if [ -f application-prod.properties ]
  then
    echo "file application-prod.properties already exists"
  else
    touch application-prod.properties
fi



cat > application-prod.properties  << EOF

# This property allows the server to run behind a proxy server and still resolve all the urls correctly
server.forward-headers-strategy=NATIVE

# Ensures that the size of the request object that we handle is controlled. By default it's 212KB.
spring.codec.max-in-memory-size=10MB

spring.data.mongodb.auto-index-creation=false

# Appsmith Marketplace
marketplace.base-url = https://release-marketplace.appsmith.com/api/v1

#Mongo properties
spring.data.mongodb.database=$mongo_database
spring.data.mongodb.uri=mongodb://$mongo_root_user:$mongo_root_pass@$mongo_host/$mongo_database?retryWrites=true
spring.data.mongodb.authentication-database=admin

# Log properties
logging.level.root=info
logging.level.com.appsmith=debug
logging.pattern.console=%X - %m%n

#Spring security
spring.security.oauth2.client.registration.google.client-id=869021686091-9b84bbf7ea683t1aaefqnmefcnmk6fq6.apps.googleusercontent.com
spring.security.oauth2.client.registration.google.client-secret=9dvITt4OayEY1HfeY8bHX74p
spring.security.oauth2.client.provider.google.userNameAttribute=email

spring.security.oauth2.client.registration.github.client-id=ffa2f7468ea72758871c
spring.security.oauth2.client.registration.github.client-secret=b9c81a1a3216328b55a7df2d49fe2bbb6b1070f1
spring.security.oauth2.client.provider.github.userNameAttribute=login

# Accounts from specific domains are allowed to login
oauth2.allowed-domains=
#oauth2.allowed-domains=appsmith.com

# Segment & Rollbar Properties
# These properties are intentionally set to random values so that events are not sent to either of them during local development
segment.writeKey=random-write-key
com.rollbar.access-token=random-rollbar-token

# Redis Properties
spring.redis.host=redis
spring.redis.port=6379

# ACL config parameters
acl.host=http://opa:8181/v1/data
acl.package.name=/appsmith/authz/url_allow

# Mail Properties
mail.enabled=true
spring.mail.host=email-smtp.us-east-1.amazonaws.com
spring.mail.port=587
spring.mail.username=AKIAVWHAAGIQOHPT4BZ7
spring.mail.password=BEE5W6i7YznAJ/YDOLbppovmOlRzxXElJ+uJtGhdCfjY
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true


EOF
