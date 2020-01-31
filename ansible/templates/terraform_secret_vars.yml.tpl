# Use API keys rather than instance roles so that tenant containers don't get
# Openshift's EC2/EBS permissions
infra_cloudprovider_secrets: {
  openshift_cloudprovider_aws_access_key: '${aws_access_key}',
  openshift_cloudprovider_aws_secret_key: '${aws_secret_key}'
}
