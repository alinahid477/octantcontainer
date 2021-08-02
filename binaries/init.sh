#!/bin/bash
export $(cat /root/.env | xargs)
export KUBECTL_VSPHERE_PASSWORD=$(echo $TKG_VSPHERE_CLUSTER_PASSWORD | xargs)
chmod 600 /root/.ssh/id_rsa
printf "\n\n\n***********Starting tunnel...*************\n"


EXISTING_JWT_EXP=$(awk '/users/{flag=1} flag && /'$TKG_VSPHERE_CLUSTER_ENDPOINT'/{flag2=1} flag2 && /token:/ {print $NF;exit}' /root/.kube/config | jq -R 'split(".") | .[1] | @base64d | fromjson | .exp')

if [ -z "$EXISTING_JWT_EXP" ]
then
    EXISTING_JWT_EXP=$(date  --date="yesterday" +%s)
fi
CURRENT_DATE=$(date +%s)


if [ "$CURRENT_DATE" -gt "$EXISTING_JWT_EXP" ]
then
    printf "\n\n\n**********vSphere Cluster login...*************\n"

    if [ -z "$BASTION_HOST" ]
    then
        rm /root/.kube/config
        rm -R /root/.kube/cache
        kubectl vsphere login --tanzu-kubernetes-cluster-name $TKG_VSPHERE_CLUSTER_NAME --server kubernetes --insecure-skip-tls-verify -u $TKG_VSPHERE_CLUSTER_USERNAME
        kubectl config use-context $TKG_VSPHERE_CLUSTER_NAME
    else
        printf "\n\n\n***********Creating Tunnel through bastion $BASTION_USERNAME@$BASTION_HOST ...*************\n"
        ssh-keyscan $BASTION_HOST > /root/.ssh/known_hosts
        ssh -i /root/.ssh/id_rsa -4 -fNT -L 443:$TKG_SUPERVISOR_ENDPOINT:443 $BASTION_USERNAME@$BASTION_HOST


        printf "\n\n\n***********Authenticating to cluster $TKG_VSPHERE_CLUSTER_NAME-->IP:$TKG_VSPHERE_CLUSTER_ENDPOINT  ...*************\n"
        rm /root/.kube/config
        rm -R /root/.kube/cache
        # echo "debug: kubectl vsphere login --tanzu-kubernetes-cluster-name $TKG_VSPHERE_CLUSTER_NAME --server kubernetes --insecure-skip-tls-verify -u $TKG_VSPHERE_CLUSTER_USERNAME"
        RESULT=$(kubectl vsphere login --tanzu-kubernetes-cluster-name $TKG_VSPHERE_CLUSTER_NAME --server kubernetes --insecure-skip-tls-verify -u $TKG_VSPHERE_CLUSTER_USERNAME)
        echo $RESULT
        # cat < ~/.kube/config

        printf "\n\n\n***********Adjusting your kubeconfig...*************\n"

        sed -i 's/kubernetes/'$TKG_SUPERVISOR_ENDPOINT'/g' ~/.kube/config
        kubectl config use-context $TKG_VSPHERE_CLUSTER_NAME

        sed -i '0,/'$TKG_VSPHERE_CLUSTER_ENDPOINT'/s//kubernetes/' ~/.kube/config
        ssh -i /root/.ssh/id_rsa -4 -fNT -L 6443:$TKG_VSPHERE_CLUSTER_ENDPOINT:6443 $BASTION_USERNAME@$BASTION_HOST        
    fi
else
    printf "\n\n\nCuurent kubeconfig has not expired. Using the existing one found at .kube/config\n"
    if [ -n "$BASTION_HOST" ]
    then
        printf "\n\n\n***********Creating Tunnel through bastion $BASTION_USERNAME@$BASTION_HOST ...*************\n"
        ssh -i /root/.ssh/id_rsa -4 -fNT -L 6443:$TKG_VSPHERE_CLUSTER_ENDPOINT:6443 $BASTION_USERNAME@$BASTION_HOST
    fi
fi


printf "\n\n\n***********Verifying...*************\n"
kubectl get ns

printf "\nDid it list the namespaces in the k8s? If not something went wrong. Please verify the env variables and check connectivity."

printf "\n\n\nGoing to launch octact.\n"

octant