# blackmatter-atlassian

Declarative Atlassian CLI provisioning via home-manager. Manages `~/.config/acli/`
config files and injects API tokens into the macOS Keychain so `acli`, `acli jira`,
`acli confluence`, and `acli rovodev` work without manual `auth login` flows.

## HM Module Options

```nix
blackmatter.components.atlassian = {
  enable = true;
  defaultSite = "akeyless";    # Which site is default for CLI ops

  sites.akeyless = {
    siteUrl = "https://akeyless.atlassian.net";
    email = "user@akeyless.io";
    accountId = "712020:xxxx-xxxx-xxxx";  # From /rest/api/3/myself

    jira.enable = true;         # Provision jira CLI profile
    confluence.enable = true;   # Provision confluence CLI profile

    rovodev.enable = true;      # Provision Rovo Dev AI agent
    rovodev.tokenFile = "~/.config/atlassian/akeyless/rovodev-token";
  };

  # Multiple sites supported:
  # sites.pleme = { siteUrl = "https://pleme.atlassian.net"; ... };
};
```

## What gets provisioned

| File | Content |
|------|---------|
| `~/.config/acli/rovodev_config.yaml` | Email, accountId, auth_type |
| `~/.config/acli/jira_config.yaml` | Jira profiles per site |
| `~/.config/acli/confluence_config.yaml` | Confluence profiles per site |
| `~/.config/acli/config.yaml` | Default site URL |
| `~/.config/acli/global_*.yaml` | Global acli settings |
| macOS Keychain `acli` entry | Rovo Dev API token (injected on activation) |

## Getting the accountId

```bash
curl -s -u "email:$(cat ~/.config/atlassian/akeyless/api-token)" \
  "https://akeyless.atlassian.net/rest/api/3/myself" | jq .accountId
```

## Multi-site support

Add more entries under `sites` for additional Atlassian instances.
Each gets its own Jira/Confluence profile and optional Rovo Dev token.
