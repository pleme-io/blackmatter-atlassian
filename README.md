# blackmatter-atlassian

Declarative Atlassian CLI provisioning via home-manager. Manages `~/.config/acli/`
config files and injects API tokens into the macOS Keychain so `acli`, `acli jira`,
`acli confluence`, and `acli rovodev` work without manual `auth login` flows.

## Usage

Add as a flake input and consume the HM module:

```nix
{
  inputs.blackmatter-atlassian.url = "github:pleme-io/blackmatter-atlassian";

  outputs = { self, blackmatter-atlassian, ... }: {
    homeConfigurations.you = home-manager.lib.homeManagerConfiguration {
      modules = [
        blackmatter-atlassian.homeManagerModules.default
        ({ ... }: {
          blackmatter.components.atlassian = {
            enable = true;
            defaultSite = "akeyless";

            sites.akeyless = {
              siteUrl = "https://akeyless.atlassian.net";
              email = "user@akeyless.io";
              accountId = "712020:xxxx-xxxx-xxxx";
              jira.enable = true;
              confluence.enable = true;
              rovodev.enable = true;
              rovodev.tokenFile = "~/.config/atlassian/akeyless/rovodev-token";
            };

            # Multiple sites supported — add more entries under `sites`.
          };
        })
      ];
    };
  };
}
```

## What gets provisioned

| File | Content |
|------|---------|
| `~/.config/acli/rovodev_config.yaml`   | Email, accountId, auth_type (per default site) |
| `~/.config/acli/jira_config.yaml`      | Jira profiles per configured site |
| `~/.config/acli/confluence_config.yaml`| Confluence profiles per configured site |
| `~/.config/acli/config.yaml`           | Default site URL |
| `~/.config/acli/global_*.yaml`         | Global acli settings |
| macOS Keychain `acli` entry            | Rovo Dev API token (injected on activation) |

## Getting the accountId

```bash
curl -s -u "email:$(cat ~/.config/atlassian/<site>/api-token)" \
  "https://<site>.atlassian.net/rest/api/3/myself" | jq .accountId
```

## Development

```bash
nix develop                # enter dev shell (nixpkgs-fmt, nil, nixd, jq)
nix flake check            # evaluate the HM module (smoke test)
nix build .#checks.aarch64-darwin.eval-hm-module
```

## License

MIT
