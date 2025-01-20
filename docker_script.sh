#!/bin/bash

# Variables
DOCKER_USER="oscarparro27"

cd img
docker login -u "$DOCKER_USER" 

#<<'EOF'
#vnf-access
cd vnf-access

echo "Construyendo la imagen Docker para vnf-access..."
docker build -t $DOCKER_USER/vnf-access . 

echo "Subiendo la imagen al repositorio Docker Hub..."
docker push $DOCKER_USER/vnf-access
cd .. 

#vnf-cpe
cd vnf-cpe

echo "Construyendo la imagen Docker para vnf-cpe..."
docker build -t $DOCKER_USER/vnf-cpe . 

echo "Subiendo la imagen al repositorio Docker Hub..."
docker push $DOCKER_USER/vnf-cpe
cd .. 

#vnf-wan
cd vnf-wan

echo "Construyendo la imagen Docker para vnf-wan..."
docker build -t $DOCKER_USER/vnf-wan . 

echo "Subiendo la imagen al repositorio Docker Hub..."
docker push $DOCKER_USER/vnf-wan
cd .. 

#EOF

#vnf-ctrl
cd vnf-ctrl

echo "Construyendo la imagen Docker para vnf-ctrl..."
docker build -t $DOCKER_USER/vnf-ctrl . 

echo "Subiendo la imagen al repositorio Docker Hub..."
docker push $DOCKER_USER/vnf-ctrl
cd .. 

echo "Proceso completado exitosamente."
