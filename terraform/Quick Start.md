# Set Up an Amazon ElastiCache for Redis cluster using Terraform

In this project, I focus only on how to provision an Amazon ElastiCache for the Redis cluster.

### Deploy

```bash
$ cd elasticache-redis-cluster/terraform
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

### Cleanup

***

To destroy all resources, run ```terraform destroy -var-file="terraform.tfvars" -auto-approve```
