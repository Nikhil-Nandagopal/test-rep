#!/bin/sh

if [ -f docker-compose.yml ]
  then
    echo "file docker-compose.yml already exists"
  else
    touch docker-compose.yml
fi



cat > docker-compose.yml  << EOF

version: "3.7"

services:
  nginx:
    image: appsmith/appsmith-editor
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./data/nginx:/etc/nginx/conf.d
      - ./data/certbot/conf:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot
    # - ./data/nginx/htpasswd:/etc/nginx/.htpasswd
    # This command reloads Nginx every 6 hours to ensure new SSL certificates via Letsencrypt are honoured 
    command: "/bin/sh -c 'while :; do sleep 6h & wait \$\${!}; nginx -s reload; done & nginx -g \"daemon off;\"'"
    depends_on: 
      - appsmith-internal-server
    networks:
      - appsmith
  
  certbot:
    image: certbot/certbot
    volumes:
      - ./data/certbot/conf:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot
    # Renew the certificates every 12 hours
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait \$\${!}; done;'"
    networks:
      - appsmith

  appsmith-internal-server:
    image: appsmith/appsmith-server:latest
    environment:
      - SPRING_CONFIG_LOCATION=/config/
      - SPRING_PROFILES_ACTIVE=prod
    volumes:
      - ./data/appsmith-server/config:/config
    ports:
      - "8080:8080"
    links:
      - mongo
    depends_on:
      - mongo
    networks:
      - appsmith

  mongo:
    image: mongo
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_DATABASE=appsmith
      - MONGO_INITDB_ROOT_USERNAME=$mongo_root_user
      - MONGO_INITDB_ROOT_PASSWORD=$mongo_root_pass
    volumes:
      - ./data/mongo/db:/data/db
      - ./data/mongo/init.js:/docker-entrypoint-initdb.d/init.js:ro  
    networks:
      - appsmith

  redis:
    image: redis
    ports:
      - "6379:6379"
    networks:
      - appsmith

  opa:
    image: openpolicyagent/opa
    command: "run --server -c /config/config.yml"
    volumes:
      - ./data/opa/config/:/config
    environment:
      - APPSMITH_SERVER_URL=http://appsmith-internal-server:8080/public
    ports:
      - "8181:8181"
    networks:
      - appsmith

networks:
  appsmith:
    driver: bridge


EOF
