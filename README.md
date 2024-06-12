<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

OPSWAT MetaDefender products are adapting year over year for our customers to get advantage of the new technologies that are coming. With this project you will be able to deploy some of our MetaDefender products to a Kubernetes Cluster. We provide you with some architecture recommendations for the main cloud providers to host the Kubernetes cluster together with an script to provision such recommended architecture. Also we provide you with all the information of the components that will be installed inside the cluster to run our products and a script to install it depending on the different configuration options.


Main Metadefender documentation pages:

* AWS Cloud Deployment Architectures Recommended [Doc](https://docs.opswat.com/mdcore/cloud-deployment/recommended-architectures-in-aws)
* MetaDefender Core Provisioned in AWS EKS [Doc](https://docs.opswat.com/mdcore/cloud-deployment/eks-cluster-architecture)
* MetaDefender Core Kubernetes Components [Doc](https://docs.opswat.com/mdcore/kubernetes-configuration/kubernetes-components)
* MetaDefender Core In Your Already Created Kubernetes Cluster [Doc](https://docs.opswat.com/mdcore/kubernetes-configuration/metadefender-core-in-your-already-created-k8s)
* MetaDefender for Secure Storage Kubernetes deployment [Doc](https://docs.opswat.com/mdss/installation/kubernetes-deployment)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

* In case of provisioning with the MetaDefender scipt the resources recommended from OPSWAT 
    * Knowledge of choosen CSP: OPSWAT assume familiarity with AWS or Azure in case you provision the infrastructure with the MetaDefender Script  
    * Account of the choosen CSP to create all the resources needed 
* Scripting languages supported: Linux - shell
* Pre-requisites:
    * [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    * [Helm](https://helm.sh/docs/intro/install/)
    * [AWS-CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    * [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)


### Installation

 OPSWAT has prepared a recommended architecture for having Metadefender products deployed in a Kubernetes Cluster in the main CSP. 
 Depending on the architecture prefered the installation process is different as each product has its own configuration options. To facilitate the deployment of the product we have created what we call MetaDefender K8S script that will guide you through the different options and configure the enviroment for you. 

 There are two modes for using the script provision and install. 

 For provision in AWS follow this [doc](https://docs.opswat.com/mdcore/cloud-deployment/metadefender-core-provisioned-in-aws-eks)
 For install MD Core in an already created cluster follow this [doc](https://docs.opswat.com/mdcore/kubernetes-configuration/metadefender-core-in-your-already-created-k8s)


<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/newGreatEnhancement`)
3. Commit your Changes (`git commit -m 'Add some new great enhancement'`)
4. Push to the Branch (`git push origin feature/newGreatEnhancement`)
5. Open a Pull Request

<p align="right">(<a href="#top">back to top</a>)</p>


<!-- LICENSE -->
## Licensing

For running MetaDefender products you will need to set up the license needed for each of the products, in case of not having such license key please contact Sales: sales-inquiry@opswat.com. 

In case of having any issue with your license please contact [Support](https://www.opswat.com/support)

For other [questions](https://www.opswat.com/contact)


<p align="right">(<a href="#top">back to top</a>)</p>


<!-- CONTACT -->
## Contact

**OPSWAT Contact Information**

* Sales: sales-inquiry@opswat.com
* Support: https://www.opswat.com/support
* Contact US: https://www.opswat.com/contact

MetaDefender Core Documentation: [https://docs.opswat.com/mdcore](https://docs.opswat.com/mdcore)
MetaDefender for Secure Storage Documentation: [https://docs.opswat.com/mdss](https://docs.opswat.com/mdss)

<p align="right">(<a href="#top">back to top</a>)</p>
