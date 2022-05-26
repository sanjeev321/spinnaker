# Start Halyard Container
mkdir ~/.hal
docker run --name halyard -v ~/.hal_local:/home/spinnaker/.hal -v ~/.kube/config:/home/spinnaker/.kube/config -d gcr.io/spinnaker-marketplace/halyard:stable

# Get a shell into Halyard container

docker exec -it halyard bash

hal config provider kubernetes enable

hal config provider kubernetes account add spinnaker --provider-version v2 --context $(kubectl config current-context)

hal config features edit --artifacts true

hal config deploy edit --type distributed --account-name spinnaker

# Install minio in kubernetes cluster

kubectl create ns spinnaker
helm install minio --namespace spinnaker --set accessKey="myaccesskey" --set secretKey="mysecretkey" --set persistence.enabled=false stable/minio
# In halyard container 
# For minio, disable s3 versioning
mkdir ~/.hal/default/profiles
echo "spinnaker.s3.versioning: false" > ~/.hal/default/profiles/front50-local.yml
# Set the storage type to minio/s3
hal config storage s3 edit --endpoint http://minio:9000 --access-key-id "myaccesskey" --secret-access-key "mysecretkey"
hal config storage s3 edit --path-style-access true
hal config storage edit --type s3
# Choose spinnaker version to install
hal version list
hal config version edit --version <desired-version>
# All Done! Deploy Spinnaker in Kubernetes Cluster
hal deploy apply
Change the service type to either Load Balancer or NodePort
kubectl -n spinnaker edit svc spin-deck
kubectl -n spinnaker edit svc spin-gate

# Update config and redeploy
hal config security ui edit --override-base-url "http://<LoadBalancerIP>:9000"
hal config security api edit --override-base-url "http://<LoadBalancerIP>:8084"
hal deploy apply


#If you used NodePort
hal config security ui edit --override-base-url "http://<worker-node-ip>:<nodePort>"
hal config security api edit --override-base-url "http://worker-node-ip>:<nodePort>"
hal deploy apply

kubectl port-forward spin-gate-b958d97b5-6lp6c  8084 -n spinnaker -s https://localhost:53501
kubectl port-forward spin-deck-6f8d5b4dc6-zddzw  9000 -n spinnaker -s https://localhost:53501 

# Spinnaker Version update 

hal config version edit --version <version>
hal deploy apply

# Enable jenkins

hal config ci jenkins master add my-jenkins-master --address http://localhost:8080 --username admin --password password