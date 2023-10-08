# Coolbet


A DevOps Engineer test task. It consists of the Infrastructure part (two questions), and the Kubernetes Network Policy evaluation part (multiple questions). The [ansible](/ansible/) folder is for the Ansible Task question, while the [logs](/logs) folder is for the Log Rotation question.



## Infrastructure

### Question 1

```sh
#!/usr/bin/env bash

int=1

for old_name in `ls | grep abc.log | sort -n -t . -k 3`; do
    new_name=abc.log.$int
    mv $old_name $new_name
    echo "$old_name -> $new_name"
    int=$(($int+1))
done
```

The code can be found [here](/logs/rotate_logs.sh).

An assumption I made is that the log files have a prefix of `abc.log.`, so I wrote the code to list all the files in the log directory (while also assuming that I'm running the code from within the log directory), get a list of the log files using the `abc.log.` prefix, sort the list using the `sort` function (I set it to sort the third column-index using `-k 3`, I specified `.` as the delimiter/field separator using `-t .`, I instructed it to sort the index numerically using `-n`),and I used a for-loop to rename the files using the `abc.log.` prefix while replacing the third column/index with numbers starting from `0` and incrementing it by `1` for every loop in the order in which the files were sorted.

After writing this code, I noticed that it wasn't a very good practice to manipulate logs directly because they might get deleted mistakenly, so I updated the code to take those logs, rotate them, and store the rotated logs in a separate directory, in this case [rotated_logs](/logs/rotated_logs).


```sh
#!/usr/bin/env bash

int=1

mkdir -p rotated_logs

for old_name in `ls | grep abc.log | sort -n -t . -k 3`; do
    new_name=rotated_logs/abc.log.$int
    cp $old_name $new_name
    echo "$old_name -> $new_name"
    int=$(($int+1))
done
```

The code can be found [here](/logs/rotate_logs_bp.sh).

You can test this code by cloning this repository locally, running [generate_logs.sh](/logs/generate_logs.sh) to generate some logs, running either of the scripts above, and then checking the [logs](/logs/) or [logs/rotated_logs](/logs/rotated_logs) folder for the rotated logs (depending on the code you run). You can clean up with [delete_logs.sh](/logs/delete_logs.sh) when you're done.


### Question 2

```yaml
---
- name: Playbook
  hosts: localhost
  connection: local
  become: true
  tasks:
    - name: Sorting
      command: bash modify.sh
      register: output

    - name: Print Output
      debug:
        var: output.stdout
```

The playbook can be found [here](/ansible/playbook.yml).

It was written to run the commands specified in the [modify.sh](/ansible/modify.sh) file.

```sh
awk -F: '{if($3 > 100){print $0}}' /etc/passwd | sort -t ':' -k 3 -n > /tmp/passwd.txt

export status_1=$?

awk -F: '{if($3 >= 0 && $3 <= 100){print $0}}' /etc/passwd | sort -t ':' -k 3 -r -n >>/tmp/passwd.txt

export status_2=$?

echo "--Sorting ids >100 completed with status $status_1, while sorting ids <=100 also completed with status $status_2--"
```

Requirements for running this code are a Linux machine with [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) installed. You must be `root` for this playbook to run successfully.

After the requirements have been met, run `ansible-playbook playbook.yml` on a terminal opened from, or set to within the [ansible](/ansible/) folder.

I won't post my own results here for security reasons, but you can check if it worked by comparing the `/etc/passwd` file and the `/tmp/passwd.txt` files by running `cat /etc/passwd` and `cat /tmp/passwd.txt` in two terminal windows side by side.

The `Print Output` task was added to the [playbook](/ansible/playbook.yml) just to show the status reports of the `Sorting` task.




## Kubernetes Network Policy Evaluation

### 1. Description of Kubernetes Network Policies

Kubernetes network policies are components used for managing the flow of network traffic within a kubernetes cluster.
They enable you define rules that govern pod-to-pod communication, pod communication across different parts of the cluster, and also how pods communicate with external resources.

They allow you implement isolation and segmentation/microsegmentation where you can configure very fine-grained traffic flow and access policies for pods, and this is very useful in multi-tenant clusters to reduce the blast radius of potential security breaches. For example, if a bad actor or exploit somehow gains access into a pod in a multi-tenant cluster, they won't be able to do much especially when the network policies have been configured properly.

They enable compliance too by making sure the pods follow specific patterns of communication, e.g. only specific pods can access the database due to the fact that sensitive data might be stored there.

They significantly enhance the security of a cluster when they are configured properly, while also allowing prioritization of critical traffic and minimizing unnecessary communication, thereby optimizing the cluster.

They scale dynamically too, enabling newly created pods to automatically inherit the network policies of their respective namespaces.

Network policies are not native to Kubernetes, neither are they automatically available on Kubernetes clusters, they are defined using the NetworkPolicy Custom Resource Definition (CRD) which extends the Kubernetes API, and they only work when a Container Network Interface (CNI) is deployed and configured on the cluster. The CNI is the one that implements the rules on the NetworkPolicy CRD. Examples of CNIs are [Calico](https://www.tigera.io/project-calico/), [Weave Net](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/), and [Cilium](https://cilium.io/).


### 2. Comparison of the given network policies


```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-backup-network-policy
spec:
  ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: backup-ns
        podSelector:
          matchLabels:
            name: backup-pod
    ports:
      - port: 5432
        protocol: TCP
  podSelector:
    matchLabels:
      name: database-pod
  policyTypes:
  - Ingress
```

This network policy allows pods in the source namespace to access pods on the destination namespace (the namespace in which the network policy is deployed) only through the specified port on the target application using TCP, meaning the port of the application is the only part that is exposed to the ingress.

In this scenario, it allows ingress traffic from pods labelled `name=backup-pod` in the `backup-ns` namespace to access port `5432` on the pods labelled `name=database-pod` in the `default` namespace using TCP (resources are deployed automatically to the default namespace when a namespace isn't specified in its manifest).

This is a relatively more fine-grained control because it exposes only a specific part/service of the pod, and this is important when the pod exposes more than one servive at a time, or it's a multi-container pod, meaning there will be relatively smaller blast radius if a breach happens.

Use cases are monitoring and logging systems for collecting metrics and logs using a specific port of the pod, exposing a database for access on a single port (e.g postgres on 5432), using a reverse proxy in a pod (e.g exposing a react app with nginx using port 80), running an API service in a pod (e.g exposing a FastAPI API service via port 5000), etc.

It implements the principle of least privileged by exposing only the required port for the required communication or ingress.


```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-backup-network-policy
spec:
  ingress:
    - ports:
      - port: 5432
        protocol: TCP
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backup-ns
          podSelector:
            matchLabels:
              name: backup-pod
  podSelector:
    matchLabels:
      name: database-pod
  policyTypes:
  - Ingress
```

This network policy allows pods labelled `name=backup-pod` in the `backup-ns` namespace to access all ports on pods labelled `database-pod` in the `default` namespace using any network protocol they require to communicate, while also allowing other pods or resources from anywhere on the cluster to access port 5432 of pods labelled `database-pod` in the `default` namespace using TCP.

This type of network policy can used for troubleshooting/monitoring, for multi-container pods that want to expose multiple services which are required by different pods in another namespace while also exposing a single application to all parts of the cluster via a specific port.

A use case in an organisation is giving the `sre` namespace access to the pods of the frontend pods in the `production` namespace to enable the many tools in the `sre` namespace execute multiple maintenance and troubleshooting tasks using different communication protocols, and at the same time serving the React application running on those pods with NGINX on port `80` to be accessed by a load balancer.


### 3. Factors to consider when evaluating the effectiveness of a Kubernetes Network Policy

1. Making sure the communication requirements of the application (such as the applications and resources that need to access it to function, and also the applications and resources it needs to access to function) are catered for by the policy. The ingress and egress rules need to reflect this.
2. The intended scope (cluster-wide, across multiple namespaces, within a single namspace, targetting a single pod, targetting a single port on an application, or communicating with external networks/resources) must be reflected in the policy.
3. The policies have to match the set goals of the organization. These goals are most times born from the collaboration between the developer, DevOps, and security teams. Tools like [kube-bench](https://aquasecurity.github.io/kube-bench/v0.6.15/), [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/), and even [Datree](https://www.datree.io/) can be configured to test the network policies to ensure the specified goals are met, the rules are properly defined, and the labels and selectors are properly configured. CI tools can also be used to run tests such as communicating with the pod from a whitelisted pod/namespace/resource, or communicating with it from a non-whitelisted pod/namespace/resource. Penetration testing should also be conducted on the pods for which the policy is defined. It should pass all these tests.
4. The network policy scope and goals must be compliant with the regulatory bodies of the industry which the application services, e.g ensuring network policies of healthcare applications are HIPAA compliant.
5. Ensuring that default policies aren't conflicting with the application requirements because Kubernetes uses the default policy when no explicitly set rules match.
6. Analysing the performance of the application before and after the network policy is implemented. This lets you know if there are any issues. A network policy shouldn't degrade the performance of an application. Higher latency might be an indication of complex policies, or policy misconfiguration.

### 4. A test deployment of network policies.

I deployed an EKS cluster and installed `Calico CNI` on it using [this script](/network_policy/cluster.sh) while also creating three namespaces (`prod`, `sre`, and `accounting`), then I deployed a multi-container pod (frontend and backend) in the `prod` namespace, and then NGINX pods to both the `sre` and `accounting` namespaces. All the dployments specify just one replica, so each namespace contained just one pod for ease of testing. I wrote network policies similar to the ones in the task by adding a namespace (prod) to let them be deployed to the `prod` namespace. I also wrote scripts to test the access of the pods in the other namespaces to the pod in the `prod` namespace.

Note that you can use any kubernetes cluster for this, you just have to check the [Calico](https://www.tigera.io/project-calico/) website for the appropriate way to deploy and configure the CNI.

[This](/network_policy/net_pol_1.yaml)...
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-backup-network-policy
  namespace: prod
spec:
  ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: sre
        podSelector:
          matchLabels:
            app: nginx
    ports:
      - port: 5000
        protocol: TCP
  podSelector:
    matchLabels:
      name: app
  policyTypes:
  - Ingress
```

...when tested with [this](/network_policy/test_pol_1.sh) returns...
```sh
Olumayowa Taiwo@DESKTOP-FEF0JUT MINGW64 ~/Documents/Projects/coolbet/network_policy (main)
$ bash test_pol_1.sh
networkpolicy.networking.k8s.io/allow-db-backup-network-policy created
----------------------------------------------------------------------------------------
Attempting to access port 5000 of Pod in Prod namespace with Pod in Accounting Namespace
________________________________________________________________________________________
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:09 --:--:--     0
curl: (28) Failed to connect to 172.16.123.4 port 5000 after 10000 ms: Timeout was reached
command terminated with exit code 28
----------------------------------------------------------------------------------------
Attempting to access port 3000 of Pod in Prod namespace with Pod in Accounting Namespace
________________________________________________________________________________________
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:10 --:--:--     0
curl: (28) Failed to connect to 172.16.123.4 port 3000 after 10001 ms: Timeout was reached
command terminated with exit code 28
---------------------------------------------------------------------------------
Attempting to access port 5000 of Pod in Prod namespace with Pod in SRE Namespace
_________________________________________________________________________________
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    61  100    61    0     0  26079      0 --:--:-- --:--:-- --:--:-- 30500
{"message":"This is a very simple message from the backend"}
----------------------------------------------------------------------------------
Attempting to access port 3000 of Pod in Prod namespace with Pod in SRE Namespace
__________________________________________________________________________________
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:10 --:--:--     0
curl: (28) Failed to connect to 172.16.123.4 port 3000 after 10001 ms: Timeout was reached
command terminated with exit code 28
```

...while [this](/network_policy/net_pol_2.yaml)...
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-backup-network-policy
  namespace: prod
spec:
  ingress:
    - ports:
      - port: 5000
        protocol: TCP
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: sre
          podSelector:
            matchLabels:
              app: nginx
  podSelector:
    matchLabels:
      name: app
  policyTypes:
  - Ingress
```

...when tested with [this](/network_policy/test_pol_2.sh) returns...

```sh
Olumayowa Taiwo@DESKTOP-FEF0JUT MINGW64 ~/Documents/Projects/coolbet/network_policy (main)
$ bash test_pol_2.sh
networkpolicy.networking.k8s.io/allow-db-backup-network-policy created
----------------------------------------------------------------------------------------
Attempting to access port 5000 of Pod in Prod namespace with Pod in Accounting Namespace
________________________________________________________________________________________
{"message":"This is a very simple message from the backend"}
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    61  100    61    0     0  12305      0 --:--:-- --:--:-- --:--:-- 15250
----------------------------------------------------------------------------------------
Attempting to access port 3000 of Pod in Prod namespace with Pod in Accounting Namespace
________________________________________________________________________________________
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:10 --:--:--     0
curl: (28) Failed to connect to 172.16.123.4 port 3000 after 10000 ms: Timeout was reached
command terminated with exit code 28
---------------------------------------------------------------------------------
Attempting to access port 5000 of Pod in Prod namespace with Pod in SRE Namespace
_________________________________________________________________________________
{"message":"This is a very simple message from the backend"}
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    61  100    61    0     0  34059      0 --:--:-- --:--:-- --:--:-- 61000
----------------------------------------------------------------------------------
Attempting to access port 3000 of Pod in Prod namespace with Pod in SRE Namespace
__________________________________________________________________________________
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta
      name="description"
      content="Web site created using create-react-app"
    />
    <link rel="apple-touch-icon" href="/logo192.png" />
    <!--
      manifest.json provides metadata used when your web app is installed on a
      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/
    -->
    <link rel="manifest" href="/manifest.json" />
    <!--
      Notice the use of  in the tags above.
      It will be replaced with the URL of the `public` folder during the build.
      Only files inside the `public` folder can be referenced from the HTML.

      Unlike "/favicon.ico" or "favicon.ico", "/favicon.ico" will
      work correctly both with client-side routing and a non-root public URL.
      Learn how to configure a non-root public URL by running `npm run build`.
    -->
    <title>React App</title>
  <script defer src="/static/js/bundle.js"></script></head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
    <!--
      This HTML file is a template.
      If you open it directly in the browser, you will see an empty page.

      You can add webfonts, meta tags, or analytics to this file.
      The build step will place the bundled scripts into the <body> tag.

      To begin the development, run `npm start` or `yarn start`.
      To create a production bundle, use `npm run build` or `yarn build`.
    -->
  </body>
</html>
100  1711  100  1711    0     0   453k      0 --:--:-- --:--:-- --:--:--  556k
```

The test scripts, though similar, contain a command that first deploys the respective network policy, after which the specified tests run.

It can be noted from the first test that there's access to port 5000 of the pod labelled `name=app` in the `prod` namespace from the pod labelled `app=nginx` in the `sre` namespace, and that there's no other form of access.

The second test however shows that there's access to all ports of the pod labelled `name=app` in the prod namespace from the pod labelled `app=nginx` in the `sre` namespace, while there's access only to port 5000 of the pod labelled `name=app` in the `prod` namespace from the pod labelled `app=nginx` in the `accounting` namespace.

These tests are a manual way to verify that the network policies were properly configured, and they can be executed in CI/CD workflows to test the effectiveness of network policies.

Once the tests are done, you can delete the cluster using [these] steps. If your cluster was not provisioned on AWS with EKSCTL, then you can skip this step and delete the resources provisioned your own way.