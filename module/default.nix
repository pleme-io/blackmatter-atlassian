# blackmatter-atlassian — Declarative Atlassian CLI + Rovo Dev provisioning
#
# Manages ~/.config/acli/ config files and macOS Keychain credential injection
# so `acli` and `acli rovodev` work without manual `auth login` flows.
#
# Secrets (API tokens) are read from sops-deployed files at activation time.
{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.blackmatter.components.atlassian;
  homeDir = config.home.homeDirectory;

  # Build rovodev_config.yaml for each configured site
  mkRovodevConfig = site: ''
    version: 1
    profile:
        email: ${site.email}
        accountId: ${site.accountId}
        auth_type: api_token
  '';

  # Build jira_config.yaml with profiles
  mkJiraConfig = sites: let
    profiles = mapAttrsToList (name: site: ''
        - email: ${site.email}
          site_url: ${site.siteUrl}
          auth_type: api_token
    '') (filterAttrs (_: s: s.jira.enable) sites);
  in ''
    version: 1
    current_profile: "${
      if cfg.defaultSite != null
      then (cfg.sites.${cfg.defaultSite}.email)
      else ""
    }"
    profiles:
    ${concatStringsSep "\n" profiles}
  '';

  # Build confluence_config.yaml with profiles
  mkConfluenceConfig = sites: let
    profiles = mapAttrsToList (name: site: ''
        - email: ${site.email}
          site_url: ${site.siteUrl}/wiki
          auth_type: api_token
    '') (filterAttrs (_: s: s.confluence.enable) sites);
  in ''
    version: 1
    current_profile: "${
      if cfg.defaultSite != null
      then (cfg.sites.${cfg.defaultSite}.email)
      else ""
    }"
    profiles:
    ${concatStringsSep "\n" profiles}
  '';

  # Activation script: inject API tokens into macOS Keychain
  keychainScript = let
    cmds = mapAttrsToList (name: site:
      optionalString (site.rovodev.enable && site.rovodev.tokenFile != null) ''
        # Inject rovodev token for ${name}
        if [ -f "${site.rovodev.tokenFile}" ]; then
          _token="$(cat "${site.rovodev.tokenFile}")"
          _account="rovodev:${site.accountId}"
          # Delete existing entry (ignore errors)
          security delete-generic-password -s "acli" -a "$_account" 2>/dev/null || true
          # Add new entry
          security add-generic-password -s "acli" -a "$_account" -w "$_token" 2>/dev/null || true
        fi
      ''
    ) cfg.sites;
  in concatStringsSep "\n" cmds;

  siteOpts = { name, ... }: {
    options = {
      enable = mkEnableOption "this Atlassian site" // { default = true; };

      siteUrl = mkOption {
        type = types.str;
        example = "https://myorg.atlassian.net";
        description = "Atlassian Cloud site URL.";
      };

      email = mkOption {
        type = types.str;
        example = "user@company.com";
        description = "Atlassian account email.";
      };

      accountId = mkOption {
        type = types.str;
        default = "";
        example = "712020:3936f1d3-939b-4810-895c-20eb2bc58ae4";
        description = "Atlassian account ID (from /rest/api/3/myself).";
      };

      jira = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Jira CLI for this site.";
        };
      };

      confluence = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Confluence CLI for this site.";
        };
      };

      rovodev = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Rovo Dev AI agent for this site.";
        };

        tokenFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "~/.config/atlassian/akeyless/rovodev-token";
          description = "Path to file containing the Rovo Dev scoped API token. Injected into macOS Keychain at activation.";
        };

        model = mkOption {
          type = types.str;
          default = "claude-opus-4-6";
          description = "Model ID for Rovo Dev agent.";
        };

        yolo = mkOption {
          type = types.bool;
          default = false;
          description = "Auto-approve all file and bash operations (no confirmation prompts).";
        };

        theme = mkOption {
          type = types.str;
          default = "dark";
          description = "Console theme (dark, light, auto, or any Pygments theme name).";
        };

        maxOutputWidth = mkOption {
          type = types.either types.int (types.enum [ "fill" ]);
          default = "fill";
          description = "Max console output width in characters, or 'fill' for terminal width.";
        };
      };
    };
  };
in {
  options.blackmatter.components.atlassian = {
    enable = mkEnableOption "Atlassian CLI declarative provisioning";

    defaultSite = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "akeyless";
      description = "Default site name (key in sites attrset) for CLI operations.";
    };

    sites = mkOption {
      type = types.attrsOf (types.submodule siteOpts);
      default = {};
      description = "Atlassian site configurations. Each site gets its own acli profile.";
      example = {
        akeyless = {
          siteUrl = "https://akeyless.atlassian.net";
          email = "user@akeyless.io";
          accountId = "712020:...";
          rovodev.enable = true;
          rovodev.tokenFile = "~/.config/atlassian/akeyless/rovodev-token";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Deploy acli config files
    xdg.configFile = {
      "acli/global_config.yaml".text = ''
        version: 1
        fedramp: false
      '';

      "acli/global_auth_config.yaml".text = ''
        version: 1
        current_profile: ""
        profiles: []
      '';

      "acli/config.yaml".text = ''
        version: 1
        current_site: "${
          if cfg.defaultSite != null
          then cfg.sites.${cfg.defaultSite}.siteUrl
          else ""
        }"
        profiles: []
      '';

      "acli/admin_config.yaml".text = ''
        version: 1
        current_profile: ""
        profiles: []
      '';

      "acli/assets_config.yaml".text = ''
        version: 1
        current_profile: ""
        profiles: []
      '';

      "acli/brie_config.yaml".text = ''
        version: 1
        current_profile: ""
        profiles: []
      '';
    }
    # Per-site configs: rovodev, jira, confluence
    // (let
      defaultSite = if cfg.defaultSite != null then cfg.sites.${cfg.defaultSite} else null;
    in
      optionalAttrs (defaultSite != null && (defaultSite.rovodev.enable or false)) {
        "acli/rovodev_config.yaml".text = mkRovodevConfig defaultSite;
      }
      // {
        "acli/jira_config.yaml".text = mkJiraConfig cfg.sites;
        "acli/confluence_config.yaml".text = mkConfluenceConfig cfg.sites;
      }
    );

    # Deploy ~/.rovodev/config.yml for the default site's rovodev config
    home.file = mkMerge [
      (let
        ds = if cfg.defaultSite != null then cfg.sites.${cfg.defaultSite} else null;
      in
        optionalAttrs (ds != null && ds.rovodev.enable) {
          ".rovodev/config.yml".text = ''
            version: 1

            agent:
              modelId: ${ds.rovodev.model}
              streaming: true
              temperature: 0.3
              enableDeepPlanTool: true
              experimental:
                enableShadowMode: false

            atlassianConnections:
              jiraProjects: []
              enabled: true

            console:
              outputFormat: markdown
              showToolResults: true
              editingMode: EMACS
              theme: ${ds.rovodev.theme}
              maxOutputWidth: ${toString ds.rovodev.maxOutputWidth}
              enableStartupAnimations: false
              copyOnSelect: true

            mcp:
              mcpConfigPath: ~/.rovodev/mcp.json

            toolPermissions:
              default: ${if ds.rovodev.yolo then "allow" else "ask"}
              tools:
                open_files: allow
                expand_code_chunks: allow
                expand_folder: allow
                grep: allow
                create_confluence_page: allow
                update_confluence_page: allow
              bash:
                default: ${if ds.rovodev.yolo then "allow" else "ask"}
                commands:
                - command: "ls(\\s.*)?"
                  permission: allow
                - command: "cat(\\s.*)?"
                  permission: allow
                - command: "echo(\\s.*)?"
                  permission: allow
                - command: pwd
                  permission: allow
                - command: "git(\\s.*)?"
                  permission: allow
                - command: "cargo(\\s.*)?"
                  permission: allow
                - command: "nix(\\s.*)?"
                  permission: allow
                runInSandbox: false

            atlassianBillingSite:
              siteUrl: ${ds.siteUrl}

            smartTasks:
              enabled: true
              sources:
              - filesystem
          '';
        }
      )
    ];

    # Inject tokens into macOS Keychain on activation (darwin only)
    home.activation.atlassianKeychain = lib.mkIf pkgs.stdenv.isDarwin
      (lib.hm.dag.entryAfter ["writeBoundary" "sopsNix"] ''
        ${keychainScript}
      '');
  };
}
