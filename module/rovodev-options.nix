# Rovo Dev configuration options — typed schema matching ~/.rovodev/config.yml
#
# Every option maps 1:1 to the YAML config key. Types are enforced by Nix
# module system. Descriptions come from Atlassian's inline documentation.
{ lib, ... }:
with lib;
{
  options = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Rovo Dev AI agent for this site.";
    };

    tokenFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to file containing the Rovo Dev scoped API token. Injected into macOS Keychain at activation.";
    };

    # ── agent ──────────────────────────────────────────────────────
    model = mkOption {
      type = types.str;
      default = "claude-opus-4-6";
      description = "Model ID for the agent. Use /models in rovodev to list available models.";
      example = "claude-opus-4-6";
    };

    additionalSystemPrompt = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Additional system prompt appended to the agent's default system prompt.";
    };

    streaming = mkOption {
      type = types.bool;
      default = true;
      description = "Enable streaming responses from the AI model.";
    };

    temperature = mkOption {
      type = types.numbers.between 0.0 1.0;
      default = 0.3;
      description = "Temperature for AI model responses (0.0 = deterministic, 1.0 = creative).";
    };

    enableDeepPlanTool = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the deep planning tool for complex task planning.";
    };

    enableShadowMode = mkOption {
      type = types.bool;
      default = false;
      description = "Run agent on temporary workspace clone, prompting before changes are applied.";
    };

    # ── console ────────────────────────────────────────────────────
    console = {
      outputFormat = mkOption {
        type = types.enum [ "markdown" "simple" "raw" ];
        default = "markdown";
        description = "Output format for console display.";
      };

      showToolResults = mkOption {
        type = types.bool;
        default = true;
        description = "Show tool execution results in the console.";
      };

      editingMode = mkOption {
        type = types.enum [ "EMACS" "VI" ];
        default = "EMACS";
        description = "Editing mode for the prompt session.";
      };

      theme = mkOption {
        type = types.str;
        default = "dark";
        description = "Color theme for syntax highlighting. Options: dark (Dracula), light, auto, or any Pygments theme name.";
        example = "monokai";
      };

      maxOutputWidth = mkOption {
        type = types.either types.int (types.enum [ "fill" ]);
        default = "fill";
        description = "Max console output width in characters, or 'fill' for terminal width.";
      };

      enableStartupAnimations = mkOption {
        type = types.bool;
        default = false;
        description = "Enable animated startup loading screen.";
      };

      copyOnSelect = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically copy selected text to clipboard.";
      };

      customCommandPrompt = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Shell command to generate a custom prompt replacing the default '> '.";
        example = "STARSHIP_SHELL=rovodev starship prompt";
      };

      terminalTitle = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable automatic terminal tab title updates.";
        };

        displayValue = mkOption {
          type = types.str;
          default = "Rovo Dev";
          description = "Terminal tab title format. Variables: {cwd}, {project}, {branch}, {session}, {model}.";
        };
      };
    };

    # ── toolPermissions ────────────────────────────────────────────
    yolo = mkOption {
      type = types.bool;
      default = false;
      description = "Auto-approve all file and bash operations (sets all permissions to 'allow').";
    };

    toolPermissions = {
      default = mkOption {
        type = types.enum [ "allow" "ask" "deny" ];
        default = "ask";
        description = "Default permission for tools not explicitly listed.";
      };

      bash = {
        default = mkOption {
          type = types.enum [ "allow" "ask" "deny" ];
          default = "ask";
          description = "Default permission for bash commands not explicitly listed.";
        };

        runInSandbox = mkOption {
          type = types.bool;
          default = false;
          description = "Run bash commands in a sandboxed environment (macOS/Linux only).";
        };

        allowedCommands = mkOption {
          type = types.listOf types.str;
          default = [ "ls" "cat" "echo" "pwd" "git" "cargo" "nix" "rg" "fd" "tree" "head" "tail" "wc" ];
          description = "Command regexes auto-allowed without confirmation.";
        };

        env = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Extra environment variables for bash commands.";
        };
      };

      allowedExternalPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Paths allowed to be accessed outside the workspace.";
      };
    };

    # ── atlassianConnections ───────────────────────────────────────
    atlassianConnections = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Atlassian product integration (Jira, Confluence).";
      };
    };

    # ── smartTasks ─────────────────────────────────────────────────
    smartTasks = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Smart Tasks discovery.";
      };

      sources = mkOption {
        type = types.listOf types.str;
        default = [ "filesystem" ];
        description = "Task discovery sources.";
      };
    };

    # ── sessions ───────────────────────────────────────────────────
    enableWorkspaceStateSync = mkOption {
      type = types.bool;
      default = false;
      description = "Warn and offer to switch workspace git state to match session checkpoint.";
    };
  };
}
