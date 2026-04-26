# core-infra Wiki

Infrastructure as Code for the **Investments Assistant** GitHub organisation.
All GitHub and AWS infrastructure is managed declaratively via Terraform.

---

## Pages

| Page | What it covers |
|---|---|
| [GitHub Module](GitHub-Module) | Org settings, repositories, teams, environments, secrets/variables |
| [AWS Module](AWS-Module) | S3 state bucket, encryption, versioning, lifecycle rules |
| [State Management](State-Management) | Remote state in S3, state locking, backend configuration |
| [Adding a Repository](Adding-a-Repository) | How to add a new GitHub repo to the organisation |

---

## Repository layout

```
core-infra/
├── pyproject.toml               # pre-commit + dev tooling config
├── .pre-commit-config.yaml      # Terraform format/validate hooks
│
└── terraform/
    ├── build-prod.sh            # wrapper: init + plan + apply for all modules
    │
    ├── aws/                     # Module: AWS S3 remote state bucket
    │   ├── providers.tf         # AWS provider (eu-south-2)
    │   ├── backend.tf           # S3 remote state backend config
    │   ├── variables.tf         # prod_tf_state_bucket_name
    │   ├── resources.tf         # S3 bucket + versioning + encryption + lifecycle
    │   └── build-prod.sh        # module-local deploy script
    │
    └── github/                  # Module: GitHub org, repos, teams, environments
        ├── providers.tf         # GitHub provider (org: Investments-Assistant)
        ├── backend.tf           # S3 remote state backend config
        ├── variables.tf         # org settings, secrets, variables
        ├── locals.tf            # YAML → repos map; flattened env secrets/variables
        ├── organization.tf      # GitHub org settings + member management
        ├── repositories.tf      # Repos + standard files (CODEOWNERS, LICENSE, etc.)
        ├── teams.tf             # core team + maintainer memberships
        ├── environments.tf      # dev + prod environments, secrets, variables
        ├── repositories.yaml    # Declarative repository catalogue
        └── terraform.tfvars.example  # Secret values template
```

---

## Why Terraform for GitHub?

- **Auditability**: every change to repository settings, team memberships, and secrets
  goes through a PR with a `terraform plan` diff — no ad-hoc clicks in the GitHub UI
- **Consistency**: all repos get the same `CODEOWNERS`, `CODE_OF_CONDUCT`, `CONTRIBUTING`,
  and `LICENSE` files from shared templates, automatically
- **Safety**: `prevent_destroy = true` on repositories, teams, and org settings ensures
  a typo in a YAML file can't accidentally delete a repository
- **Secrets management**: GitHub Actions secrets for API keys are stored in Terraform
  state (encrypted in S3) and injected into environments without exposing them in source code
