 ## Metis: SambaNova SN40L cluster at ALCF
 
[Metis](https://docs.alcf.anl.gov/ai-testbed/sn40l_inference/) is composed of two SambaRacks—each housing 16 SN40L RDU systems. This dedicated setup delivers high-throughput, low-latency performance for machine learning workloads. 
Models running on the cluster are exposed through OpenAI-compatible API endpoints, with each endpoint capable of hosting multiple independently accessible models.

The easiest way to get started on Metis is through the web interface, accessible at https://inference.alcf.anl.gov/.

The list of currently supported chat-completion models on Metis are : gpt-oss-120b-131072 and Llama-4-Maverick-17B-128E-Instruct.
 
Additional documentation on using Metis inference endpoints is available [here](https://docs.alcf.anl.gov/ai-testbed/sn40l_inference/using_an_inference_endpoint/).
