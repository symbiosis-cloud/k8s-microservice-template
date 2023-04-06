# FAQ

## How do I find the password to Grafana?

Log in with username `admin` and password from the `grafana-password` secret in the `monitoring` namespace, you can get it with kubectl:

```bash
kubectl get secret -n monitoring grafana-password --template={{.data.password}} | base64 -d
```

## How do I access the backend over HTTPS?

The backend API is accessable at `api.<DOMAIN_NAME>` where the domain name is the value you put in the `terraform.tfvars` file. Or using curl:

```bash
curl https://api.<DOMAIN_NAME>
```

## How do I access the postgres CLI?

```bash
kubectl exec -it svc/main-database-rw psql
```
