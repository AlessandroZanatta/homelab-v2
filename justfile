

conform *ARGS:
  #!/bin/bash
  kubeconform -strict -kubernetes-version 1.29.4 -ignore-missing-schemas playbooks/cluster/templates/manifests {{ ARGS }}

lint *ARGS:
  kube-linter lint --exclude latest-tag playbooks/cluster/templates/manifests {{ ARGS }}

apply FILTER:
  ansible-playbook -i environments/prod playbooks/cluster/k8s-apps.yaml -t apply -e 'filter={{ FILTER }}'

delete FILTER:
  ansible-playbook -i environments/prod playbooks/cluster/k8s-apps.yaml -t delete -e 'filter={{ FILTER }}'
