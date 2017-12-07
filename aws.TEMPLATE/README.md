# This is a short AWS HOW-TO for your personal projects

```bash
terraform init

alias p="terraform plan --var-file=../config.json --var-file=../cpu-config.json"
alias a="terraform apply --var-file=../config.json --var-file=../cpu-config.json"
alias d="terraform destroy --var-file=../config.json --var-file=../cpu-config.json"

p
a
...
d
```
