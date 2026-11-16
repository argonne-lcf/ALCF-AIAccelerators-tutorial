
# [ALCF Inference Service](https://docs.alcf.anl.gov/services/inference-endpoints/)

The Argonne Leadership Computing Facility (ALCF) Inference service provides API access to a variety of state-of-the-art open-source models running on dedicated ALCF hardware: Sophia (Nvidia A100), Metis (SambaNova SN40L), Tara (Nvidia GH200), and Minerva (Nvidia B200).

To access the service, attendees must complete the following steps. 

Please note that access to the ALCF Inference service will remain available only until the end of the tutorial session.

## Step 1: Create or access a Globus account
If you do not already have a Globus account, create one at https://www.globus.org/.

You can sign in using one of the supported identity providers (IdPs) ```.edu, orcid, github```. Please refer to the ALCF Supported Identity Providers documentation (https://docs.alcf.anl.gov/services/inference-endpoints/#supported-identity-providers) for the list of approved providers.

For your first login, visit Globus File Manager and click LOG IN in the upper-right corner.

Join the globus group https://app.globus.org/groups/0b0f544d-df8b-11f1-aab9-0efff6ef87d5/. 

## Step 2: Use the inference service with alcf-ai CLI
[alcf-ai](https://docs.alcf.anl.gov/services/inference-endpoints/alcf-ai/) is the ALCF AI Inference Services SDK. It provides a command line interface for authentication, 
chat, endpoint discovery, image segmentation, and agent configuration.

For authentication, ```alcf-ai``` reads the tokens cached by the shared ```alcf-tokens``` CLI which can be installed by ```pip install alcf-tokens```. 
Use this command to login to the inference service:

```
alcf-tokens login inference

# Verify that the inference token is accepted:
alcf-tokens test-token inference

# Print an access token for use with curl or another client:
token=$(alcf-tokens get-token inference)

# to test your account
curl -X GET "https://inference-api.alcf.anl.gov/resource_server/whoami" \
     -H "Authorization: Bearer ${token}"


## list endpoints on clusters sophia (Nvidia A100), metis (SambaNova SN40L), tara (Nvidia GH200), and minerva (Nvidia B200)
alcf-ai ls-endpoints	List all endpoints available across clusters (raw API response).
alcf-ai ls-models <cluster>	List the models available on a cluster, with capabilities (raw API response).
alcf-ai ls-jobs <cluster>	List the ongoing jobs (running and queued models) for a cluster.


alcf-ai chat -c minerva -m beam-1.0-bf16 "How do I know Pi is irrational? Be concise."



```






 
