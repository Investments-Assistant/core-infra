# core-infra Wiki

Infrastructure as Code for the **Investments Assistant** GitHub organisation.
The repository consumes a reusable GitHub module from
`Investments-Assistant/opentofu-modules` and stores its root state locally.

---

## Pages

| Page | What it covers |
|---|---|
| [GitHub Module](GitHub-Module) | Organisation settings, repositories, teams, environments, secrets, and variables |
| [State Management](State-Management) | Local state, workspaces, locking, backups, and sensitive values |
| [Adding a Repository](Adding-a-Repository) | How to add a new repository to the organisation |

---

## Repository layout

```
core-infra/
├── pyproject.toml               # pre-commit and development tooling config
├── .pre-commit-config.yaml      # formatting, validation, and lint hooks
│
└── opentofu/
    └── github/                  # GitHub organisation, repositories, teams
        ├── providers.tofu       # GitHub provider configuration
        ├── backend.tofu         # local state backend configuration
        ├── organization-module.tofu   # organization settings and memberships
        ├── repositories-module.tofu   # repositories and governance files
        ├── team-module.tofu            # team and memberships
        ├── environments-module.tofu    # environments and Actions settings
        ├── migrations.tofu      # state address moves into the module
        ├── variables.tofu       # organisation settings, secrets, variables
        ├── locals.tofu          # repository catalogue and deployment defaults
        ├── repositories.yaml    # declarative repository catalogue
        └── env.ttvars.example    # variable and secret template
```

---

## Why OpenTofu for GitHub?

- **Auditability**: changes to repository settings, teams, and secrets go
  through a plan that can be reviewed before application.
- **Consistency**: repositories receive shared files and settings from the
  same declarative configuration.
- **Safety**: `prevent_destroy = true` protects repositories, teams, and
  organisation settings from accidental deletion.
- **Local ownership**: state stays on the machine running OpenTofu and is
  excluded from source control.
