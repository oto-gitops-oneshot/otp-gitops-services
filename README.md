# Catalog of Operators and Instances Catalog for One Touch Provisioning asset

This git repository serves as a catalog/library of Operators and Instances of the custom resource(s) provided by the Operators for the [One Touch Provisioning](https://github.com/one-touch-provisioning/otp-gitops) asset.  The Operator and Instance YAMLs are package as a Helm Chart and can be referenced by ArgoCD Applications.

The Charts are hosted in the [Cloud Native Toolkit Helm Repository](https://github.com/cloud-native-toolkit/toolkit-charts).

## Instances

Instances are deployed with mostly default options selected. You will need to modify these to suit your configurations.

### Instana

The prerequisites to install the Instana agent are:  

1. Store your Instana Agent Key in a secret in the `instana-agent` namespace. The secret key field should contain `key` and the value contains your Instana Agent Key. Modify the `instana-agent.agent.keysSecret` value in the `instances\instana-agent\values.yaml` file to match the secret you deployed. 

2. Modify the `instana-agent.cluster.name` value in the `instances\instana-agent\values.yaml` file which represents the name that will be assigned to this cluster in Instana.

3. Modify the `instana-agent.zone.name` value in the `instances\instana-agent\values.yaml` file which is the custom zone that detected technologies will be assigned to.


## CP4BA - FileNet and IER assets

The assets deployed are defined in the **kustomization.yaml** file found in the **0-bootstrap/hub/2-services/kustomization.yaml** directory in the [parent repository](https://github.com/oto-gitops-oneshot/otp-gitops). The file is laid out in a manner to make it clear what components are relevant for this use case.

First and foremost, we do plan to extend this framework to support other Cloud Paks as well. The "CloudPaks" heading should make this apparent, therein lies the different cloud paks, for instance CP4I and CP4BA.

![Parent - Services - Kustomize](Images/Kustomize_CloudPaks.png)

Scroll down a tad and divert your attention to the CP4BA heading, along with the list of the enclosed services, as shown below.

![Parent - Services - Kustomize - CP4BA](Images/Kustomize_CP4BA.png)

The applications are stood in a particular order, as dictated by [ArgoCD Sync Waves](). This sequence is, more or less, given in descending order. For instance, note the operators are deployed first, followed by the required ancillary services  (DB2 and LDAP in our case), followed by the pre-deployment, deploymant and post-deployment applications of the CP4BA Asset.


### CP4BA - Operators

The CP4BA CatalogSources and Subscription objects, as defined in the kustomization file given in the section above are found in the **operators/cloudpak/cp4ba-operator** directory of this repository. Therein lies the CatalogSources and Subscription objects, each allocated to it's corresponding sub-directory. We use the [Kustomize framework](https://kustomize.io) to standardise the method around which updates are to be performed upon the subscription channels and catalogSources in future versions of this asset. As an example, consider the **catalogsource.yaml** file found in the **operators/cloudpak/cp4ba-operator/catalog-sources/base** directory. The image field of each CatalogSource object within contains a reference to the location of the actual image in the icr repository. These references are defined in the **kustomization.yaml** file located in the **operators/cloudpak/cp4ba-operator/catalog-sources/overlays/latest** directory. Simply update the values found in this file in accordance to the requirements laid out in future versions. 

On a similar note, maintainers would simply update the **kustomization.yaml** file found in the **operators/cloudpak/cp4ba-operator/subscription/overlays/latest** to update the subscription channel, which would override the spec.channel field present in the **subscription.yaml** file located in the **operators/cloudpak/cp4ba-operator/catalog-sources/base/** directory.

As of the time of writing, we are using the latest stable version of CP4BA - that is, 22.0.1. The aformentioned YAML's were obtained from the official documentation:

1) [Case Package](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=ppd-preparing-client-connect-cluster)
2) [Procedure](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/22.0.1?topic=ppd-setting-up-cluster-in-openshift-console)

Note the links given above point to the latest stable version currently supported at the time of writing. Newer versions/links will likely be available, depending on when you read this.

In either case, the case package link contains the YAML files, and the procedure link explains how they are used.


### DB2 - Operators

The contents of the previous section also apply here. Again, please note we are using the latest stable version of the DB2 operator which, at the time of writing, is version 11.5.0.

The following [link](https://www.ibm.com/docs/en/db2/11.5?topic=SSEPGG_11.5.0/com.ibm.db2.luw.db2u_openshift.doc/doc/t_db2u_install_op_catalog.html) contains the CatalogSource specification. The Subscription is not given in the link. We "reverse-engineered" it by deploying the operator manually via the OpenShift UI and retrieving the Subscription object created as a consequence.


### DB2 - Instance

The relevant objects defining the DB2 deployment assets are housed in the **instances/db2/create** directory. We use, again, the kustomize framework to tailor each deployment given the deployment platform. The DB2UCluster CR requires a storageClassName field, which is a function of the target hyperscaler. We have tested this against ROKS, hence the presence of the **ibmcloud-roks** directory, which overrides both the version and the storageClassName accordingly. Perhaps the changes should have split across multiple files, as opposed to one to make it clear what each file is responsible for. Future work would entail structuring this in a more cohesive manner as described earlier, in addition to testing deployments to other platforms, namely AWS and Azure.

You may recall the pull secret required to pull the image is defined in the **pull-secret.yaml** file in the **instances/db2/create/base** directory. Populating this was discussed in the pre-requisite steps as given [here](https://github.com/oto-gitops-oneshot#prerequisite---secret-creation).

In either case, maintainers simply need to update the spec.version **db2ucluster.yaml** file found in the **instances/db2/create/overlays/** directory in the event of new updates, provided the relevant changes are made upstream in the **operators/db2** directory of course.

### Openldap - Instance

There is no operator deployment here, as opposed to DB2. All objects are defined as a Helm Chart located in the **instances/openldap** directory. This Helm chart is quite involved containing a multitude of components. As such, only the relevant components are outlined here.

The **values.yaml** found within the **instances/openldap** directory contains an "existingSecret" field, as seen in line 61. If value associated with this field is empty, the passwords defined in lines 19 and 20 are used instead. If the value is non empty (as in our case), a pre-existing secret, given by the value, is used instead. This pre-existing secret is defined in the **external-admin-secret** file. Note the Helm conditional locted up the top as given below. This secret is only instantiated in the event the existingSecret field in the aforementioned values file is non empty.

![Parent - Services - OpenLDAP - Secret](Images/LDAP_Existing_Secret.png)

The "adminPassword" portion of this secret defines the LDAP Adminstrator password required to login, as shown below. The URL exposing this service is defined **edgeroute.yaml** found in the **instances/openldap/templates** directory. Put simply, it is a route exposed in the **openldap** namespace. The username is prepopulated.

![Parent - Services - OpenLDAP - UI](Images/LDAP_UI.png)

A successful login shows the users and groups constituting this active directory. These entities are defined in the "customLdifFiles" stanza within the **values.yaml** located in the **instances/openldap**. The users defined are ultimately federated as CP4BA users. 

In a production setting, the customer's active directory server would most likely be used, as opposed to this custom LDAP deployment.

