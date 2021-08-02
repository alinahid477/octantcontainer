# Octant (What)

Octant is a great tool to visualise what is in a k8s cluster. You can also use it to deploy k8s yaml files. But I feel much confortable doing so through pipeline or using kubectl.

I way see it, octant is a k8s dashboard on steroid. (not to mention the native k8s dashboard doesn't get much love and isnt really friendly to navigate or visualise of a cluster and components inside a k8s cluster)

Read more about here: https://octant.dev/

The purpose of this repo is to provide a bootstrapped docker container to start octant super quickly. You can use it
- on your local machine (as I am)
- have it deployed on a VM or a k8s cluster

## Why run octant in a docker container

If you're like me, I like running everything (yes everything, even my dev environments) in docker container. Why? read here: https://github.com/alinahid477/vmw-calculator-divisionservice/ 

Running octant in docker because:

- I can spin up octant quickly. This docker container is like a bootstrapped environment with everthig in it need to generate kubeconfig file to running octant. 
- I get to keep my kubeconfig separate, meaning, I can contunie doing kubectl on my local computer as it is and have octant accessing many other different k8s clusters including my local ones.
- I can keep the whole thing in a source code repo and make it portable so that I can run it whenever and wherever I want to run it. (eg: I have used this container in few different VMs already to see few different k8s clusters)



# How


## Prepare: cli tools and .ssh private key

The below may be required
- **cli tools (optional)**
    To be placed in binaries directory. 

    - ***tmc***: This cli may be needed if you are connecting throug a tmc provided kubeconfig file. You can get this cli from the same window in tmc console (where you downloaded the kubeconfig from)
    - ***kubectl-vsphere***: This may be needed if you going to use sso login to generate kubeconfig for your 'vSphere with Tanzu' clusters (aka TKGs) which octant will be using. (you can get these clis from your vSphere: Workload Management > Select a workload > Summary tab > Status card > Click the 'Link to CLI Tools')

    ***If you do not have/require any or either of these clis then comment lines that copying (followed by run) the cli in the Dockerfile.***

- **ssh private key (optional)**
    To be placed in the the .ssh folder of this location (not your ~/.ssh). (I called it id_rsa). 

    This may be needed when you're using ssh tunnel through a bastion/jump host. If you would like to use password (or do not have the private key to bastion host's sshkey) simply skip this and do not pass the `-i .ssh/id_rsa`.



## Prepare: kubeconfig

Octant needs a k8s config file to access the k8s cluster and display its components/objects (to do what it does). The way it does it is through the kube config file.

*Kubeconfig is a yaml file that can contain connection details to multiple k8s clusters. When you do `kubectl login` on your local machine or bastion host/jump host this file is auto created by kubectl. This is a yaml file and you can also manually create or merge multiple kubeconfig file and provide to octant.* 

There're few ways to get this kube config file (depending on where your cluster is and how you access it)

- **Your local kubeconfig file (usually located at ~/.kube/config)**

    This is usually the typical way when you can access k8s cluster from your local machine (eg: The k8s cluster endpoint is public, k8s cluster is running on your local machine like minikube)

- **TMC cluster access kubeconfig file (downloaded from TMC)**
    
    When your cluster(s) is provisioned through TMC (Tanzu Mission Control) you can get a kubeconfig file from TMC. If there're multiple clusters then you can pretty much merge the contents.

- **From bastion host or Jump host**
    
    When you are accessing k8s clusters using a bastion host the kubectl file is most like going to be in the bastion host's ~/.kube/config location. download it using scp. For example : `scp -i .ssh/id_rsa ubuntu@xxx.xxx.xxx.xxx:/home/ubuntu/.kube/config .kube/`

- **Generate on the fly**

    Using the cli tools you can generate the kubeconfig file here (because this directory is mounted). Check this post here: https://github.com/alinahid477/vsphere-tkg-tunnel/tree/main. This process is automated in this docker container. 
    
    In the absense of the .kube/config file this container will attempt to create one based on the information supplied via the .env file.

    for the .env file rename the .env.sample to .env *(`mv .env.sample .env`)*  and fill out the below details:

    - BASTION_HOST={the jump or bastion host ip or name. OR leave it blank if you have direct access to kubernetes endpoint and do not need a bastion host}
    - BASTION_USERNAME={username for login into the above host. Leave it blank if there is no bastion host.}
    - TKG_SUPERVISOR_ENDPOINT={find the supervisor endpoint from vsphere (eg: Menu>Workload management>clusters>Control Plane Node IP Address)}
    - TKG_VSPHERE_CLUSTER_NAME={the k8s cluster your are trying to access}
    - TKG_VSPHERE_CLUSTER_ENDPOINT={endpoint ip or hostname of the above cluster. Grab it from your vsphere environment. (Menu>Workload Management>Namespaces>Select the namespace where the k8s cluster resides>Compute>VMware Resources>Tanzu Kubernetes Clusters>Control Plane Address[grab the ip of the desired k8s])}
    - TKG_VSPHERE_CLUSTER_USERNAME={username for accessing the cluster}
    - TKG_VSPHERE_CLUSTER_PASSWORD={password for accessing the cluster}

    
That's it. Follow along the next steps to tell octant to use ssh tunnel.


## Octant running in a docker container


Build the container using the Dockerfile:

```
docker build . -t octant
```

**There are two ways to run it**

### for k8s clusters with accessible k8s api endpoint

`docker run -it --rm -p 51234:51234 -v ${PWD}:/root/ --name octant octant`

### for remote clusters over ssh tunnel

`docker run -it --rm -p 51234:51234 -v ${PWD}:/root/ --add-host kubernetes:127.0.0.1 --name octant octant`

How / Why so? Read here: https://github.com/alinahid477/VMW/tree/main/tunnel

## This container for TMC provisioned clusters
The main reason why I am not running this container in background mode is so that when I am accessing TMC supplied kubeconfig yaml (or merged yamls) for octant it will 
- make use TMC cli 
- and ask for TMC api token

This will show up in the command prompt. Supply the token when asked.

# That's it.
You should now have octact running on port 51234.

From your local browser it should be accessible at http://localhost:51234

Fast and easy way to start octant-ing.

