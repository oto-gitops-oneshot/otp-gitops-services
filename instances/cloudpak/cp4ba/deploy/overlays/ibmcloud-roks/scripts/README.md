# Deploy Scripts to fill in the service or domain details in some overlays ICP4ACluster yaml and kustomization

These scripts were created to query the cluster for certain details that are used to patch some yaml files.

## Requirements
- awk, grep and sed
- oc, and assume session that has previously logged in to the cluster
- the scripts should all be in the same location, particularly with the common dependency on `populate_value.sh` having the shared *populate_value()* function

## Error handling
- The scripts will quit with exit code 1 in case an error is encountered. 
- The error message comes out in stdout.
- Each script hard-codes the target key for which a value is to be patched. If the key is not found, the script will write a warning message and do nothing for that target file.
- Other details are hard-coded in the scripts in different ways.

## Usage

Each of the scripts takes one or more files as input args. There are no switches or options.

    % bash <populate_script.sh> file1.yaml [file2.yaml .. ]

## The Scripts

### populate_db2_servername.sh

The script looks for the service in the db2 namespace having one port (.spec.ports[]) named *db2-server*, then takes the service name, constructs the FQDN (*service-name*.**db2.svc.cluster.local**) and patches the value for *database_servername* in the target files.

**Example:**

    % bash populate_db2_servername.sh ban.yaml cpe.yaml kustomization.yaml
    % 

For each of the target files, the script will locate the key-value assignment for key *database_severname* and put in the FQDN constructed for it.

### populate_openldap_ldap_server.sh

The script looks for the service in the openldap namespace having one port (.spec.ports[]) named *ldap-port* and where _spec.clusterIP_ is a valid IP address -- validated by regex only. The script then takes the service name, constructs the FQDN (*service-name*.**openldap.svc.cluster.local**) and patches the value for *lc_ldap_server* in the target files.

**Example:**

    % bash populate_openldap_ldap_server.sh ldap.yaml
    %


For each of the target files, the script will locate the key-value assignment for key *lc_ldap_server* and put in the FQDN constructed for it.

### populate_platform.sh

The script looks for the cluster's ingress domain by querying the cluster for the *Console URL* and taking just the domain portion. The script then constructs the FQDN (**cp4ba**.*ingress-domain*) and patches the value for *sc_deployment_hostname_suffix* in the target files.

**Example:**

    % bash populate_platform.sh platform.yaml
    %

### populate_tm.sh

The script looks for the cluster's ingress domain by querying the cluster for the *Console URL* and taking just the domain portion. The script then constructs the FQDN (**https://cpd-cp4ba**.**ingress-domain/ier/EnterpriseRecordsPlugin/IERApplicationPlugin.jar**) and patches the value for *tm_job_url* in the target files.

**Example:**

    % bash populate_tm.sh tm.yaml
    %
### populate_value.sh

This is the script file containing the shared function *populate_value()*, that each of the above scripts require.

