api_addr = "https://openbao.openbao.svc:8200"
cluster_addr = "https://127.0.0.1:8201"

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_cert_file = "/tls/tls.crt"
  tls_key_file = "/tls/tls.key"
}

storage "raft" {
  path = "/data"
  node_id = "openbao-0"
}

seal "static" {
  current_key_id = "bastille-1"
  current_key = "file:///seal/key"
}

audit "file" "stdout" {
  options {
    file_path = "stdout"
  }
}

initialize "bootstrap" {
  request "kv" {
    operation = "update"
    path = "sys/mounts/kv"
    data = { type = "kv", options = { version = "2" } }
  }
  request "auth" {
    operation = "update"
    path = "sys/auth/kubernetes"
    data = { type = "kubernetes" }
  }
  request "reviewer" {
    operation = "update"
    path = "auth/kubernetes/config"
    data = { kubernetes_host = "https://kubernetes.default.svc" }
  }
  request "operator-policy" {
    operation = "update"
    path = "sys/policies/acl/operator"
    data = { policy = "path \"*\" { capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\", \"sudo\", \"patch\"] }" }
  }
  request "operator-role" {
    operation = "update"
    path = "auth/kubernetes/role/operator"
    data = {
      bound_service_account_names = ["openbao-operator"]
      bound_service_account_namespaces = ["openbao"]
      audience = "openbao"
      token_policies = ["operator"]
      token_explicit_max_ttl = "10m"
    }
  }
  request "snapshot-policy" {
    operation = "update"
    path = "sys/policies/acl/snapshot"
    data = { policy = "path \"sys/storage/raft/snapshot\" { capabilities = [\"read\"] }" }
  }
  request "snapshot-role" {
    operation = "update"
    path = "auth/kubernetes/role/snapshot"
    data = {
      bound_service_account_names = ["openbao-snapshot"]
      bound_service_account_namespaces = ["openbao"]
      audience = "openbao"
      token_policies = ["snapshot"]
      token_explicit_max_ttl = "10m"
    }
  }
}
