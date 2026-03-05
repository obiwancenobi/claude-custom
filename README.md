<div align="center">

# Claude Custom

*An interactive Bash CLI tool that configures Claude Code's `settings.json` with your preferred AI model provider. Set up OpenRouter, Ollama, or a custom endpoint in seconds.*

<br>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Bash](https://img.shields.io/badge/Bash-4.0+-blue.svg)](https://www.gnu.org/software/bash/) [![100% Local](https://img.shields.io/badge/Local-100%25-brightgreen.svg)](https://github.com/obiwancenobi/claude-custom) [![Version](https://img.shields.io/badge/Version-1.0.0-informational)](https://github.com/obiwancenobi/claude-custom/releases)

</div>

---

## 🖼️ Preview

<img src="images/screenshot-1.png" alt="claude-custom interactive wizard" width="600"/>

## ✨ Features

- **Flexible Scope**: Configure globally (`~/.claude/settings.json`) or per-project (`.claude/settings.json`)
- **Provider Support**:
  - **OpenRouter** — Pre-configured API endpoint
  - **Ollama** — Local LLM at `localhost:11434`
  - **Custom** — Your own base URL
- **Secure Input**: API tokens entered with masked input (echo disabled)
- **Smart Merging**: Preserves existing settings while updating credentials
- **Automatic Backups**: Timestamped backups before any changes

## 🔒 Security & Privacy

**100% local operation — zero data transmission. This tool only:**

- Write to your local settings.json
- Store credentials on your machine
- Mask input during token entry
- Let you choose config location (global or project)

Your API keys never leave your computer. The script is a configuration helper only — Claude Code itself handles all API communication.

## 📋 Requirements

- **Bash** 4.0 or later
- **jq** — Command-line JSON processor

Install jq if needed:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Fedora
sudo dnf install jq

# Arch Linux
sudo pacman -S jq

# Alpine Linux
apk add jq
```

## 🚀 Installation

### Option 1: Homebrew (macOS/Linux) — Easiest

```bash
# Tap the repository (if available) or install directly
brew install obiwancenobi/claude-custom/claude-custom

# Or update and upgrade
brew update && brew upgrade claude-custom
```

### Option 2: Quick Install (One-Liner)

Download and install directly to `/usr/local/bin`:

```bash
# Using curl
curl -sSL https://raw.githubusercontent.com/obiwancenobi/claude-custom/main/claude-custom | sudo tee /usr/local/bin/claude-custom > /dev/null && sudo chmod +x /usr/local/bin/claude-custom

# Using wget
wget -qO- https://raw.githubusercontent.com/obiwancenobi/claude-custom/main/claude-custom | sudo tee /usr/local/bin/claude-custom > /dev/null && sudo chmod +x /usr/local/bin/claude-custom
```

### Option 3: Manual Installation

#### Copy (requires sudo)

```bash
sudo cp claude-custom /usr/local/bin/
sudo chmod +x /usr/local/bin/claude-custom
```

#### Symlink (no need to copy)

```bash
ln -sf "$(pwd)/claude-custom" /usr/local/bin/claude-custom
```

#### Clone & Install

```bash
git clone https://github.com/yourusername/claude-custom.git
cd claude-custom
sudo cp claude-custom /usr/local/bin/
sudo chmod +x /usr/local/bin/claude-custom
```

### Option 4: Local Use (No Install)

Run directly from the repository without installing:

```bash
./claude-custom
# or
./claude-custom --version
```

### Verify Installation

```bash
claude-custom --version
# Claude Custom v1.0.0
```

### Uninstall

```bash
sudo rm /usr/local/bin/claude-custom
```

## 🎯 Usage

Start the interactive configuration wizard:

```bash
claude-custom
```

### Command-Line Options

```bash
claude-custom --help     # Display this help message
claude-custom --version  # Show version information
```

### What Gets Configured

The tool writes these environment variables to Claude Code's `settings.json`:

| Variable | Purpose |
|-----------|---------|
| `ANTHROPIC_AUTH_TOKEN` | Your API key (required) |
| `ANTHROPIC_BASE_URL` | API endpoint URL (auto-set for OpenRouter/Ollama) |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Default Sonnet model name |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Default Opus model name |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Default Haiku model name |

## 🛠️ How It Works

1. **Choose scope** — Decide between global or project configuration
2. **Select provider** — Pick OpenRouter, Ollama, or Custom
3. **Enter credentials** — Provide API token (masked), base URL (if custom), and model names
4. **Save & backup** — Existing config is backed up with timestamp, then updated

On first run, if no configuration exists, you'll be prompted to create one. Subsequent runs will show current values and allow you to update them.

### Flow Diagram

```mermaid
flowchart TD
    Start([User runs bin/claude-custom]) --> CheckArgs{Command-line arguments?}

    CheckArgs -->|--help| ShowHelp[Show help & exit]
    CheckArgs -->|--version| ShowVersion[Show version & exit]
    CheckArgs -->|None| MainFlow[Main execution flow]

    MainFlow --> CheckJq{Check jq dependency}
    CheckJq -->|Not installed| JqError[Error & exit]
    CheckJq -->|Installed| PromptScope[Prompt for configuration scope]

    PromptScope --> GetScopeChoice{User choice}
    GetScopeChoice -->|1 Global| SetGlobal[Set CONFIG_SCOPE=global FILE_CONFIG=~/.claude/settings.json]
    GetScopeChoice -->|2 Project| SetProject[Set CONFIG_SCOPE=project FILE_CONFIG=./.claude/settings.json]
    GetScopeChoice -->|Invalid| RetryScope[Re-prompt for scope]

    SetGlobal --> ValidateWritable[Validate file is writable]
    SetProject --> ValidateWritable
    RetryScope --> PromptScope

    ValidateWritable -->|Not writable| WriteError[Error & exit]
    ValidateWritable -->|Writable| PromptProvider[Prompt for model provider]

    PromptProvider --> GetProviderChoice{User choice}
    GetProviderChoice -->|1 OpenRouter| SetOpenRouter[MODEL_PROVIDER=openrouter]
    GetProviderChoice -->|2 Ollama| SetOllama[MODEL_PROVIDER=ollama]
    GetProviderChoice -->|3 Custom| SetCustom[MODEL_PROVIDER=custom]
    GetProviderChoice -->|Invalid| RetryProvider[Re-prompt for provider]

    SetOpenRouter --> CheckConfigExists{Config file exists?}
    SetOllama --> CheckConfigExists
    SetCustom --> CheckConfigExists
    RetryProvider --> PromptProvider

    CheckConfigExists -->|Yes| ReadValues[read_existing_values]
    CheckConfigExists -->|No| PromptCreate[Ask to create new config]

    ReadValues --> DisplayCurrent[Display current config]
    PromptCreate -->|N| Abort[Exit without changes]
    PromptCreate -->|Y| Continue[Continue]
    Abort --> End

    Continue --> DisplayCurrent
    DisplayCurrent --> PromptAuth[Prompt for ANTHROPIC_AUTH_TOKEN]

    PromptAuth --> GetAuthToken{Valid token?}
    GetAuthToken -->|Empty| RetryAuth[Re-prompt for token]
    GetAuthToken -->|Valid| PromptBaseUrl[Prompt for ANTHROPIC_BASE_URL]

    RetryAuth --> PromptAuth

    PromptBaseUrl --> GetProviderLogic{Provider-specific logic}

    GetProviderLogic -->|OpenRouter| SetStaticUrl[Set static URL: https://openrouter.ai/api]
    GetProviderLogic -->|Ollama| OllamaPrompt[Show default http://localhost:11434 Allow custom]
    GetProviderLogic -->|Custom| CustomPrompt[Always prompt for custom URL]

    SetStaticUrl --> PromptModels[Prompt for all models]
    OllamaPrompt --> ValidateUrl{URL empty?}
    ValidateUrl -->|Yes| OllamaPrompt
    ValidateUrl -->|No| PromptModels
    CustomPrompt --> ValidateCustomUrl{Custom URL empty?}
    ValidateCustomUrl -->|Yes| RePromptCustom[Re-prompt]
    ValidateCustomUrl -->|No| PromptModels
    RePromptCustom --> CustomPrompt

    PromptModels --> CollectModels[Collect: Sonnet, Opus, Haiku models]

    CollectModels --> BackupPhase[Backup existing config if it exists]

    BackupPhase --> SavePhase[SaveSettings function: Merge with existing or create new JSON config]

    SavePhase --> Success[Success message and Restart instruction]

    Success --> End([Exit])

    JqError --> End
    WriteError --> End

    style Start fill:#90EE90
    style End fill:#FFB6C1
    style Success fill:#ADD8E6
    style JqError fill:#FFCCCB
    style WriteError fill:#FFCCCB
    style Abort fill:#FFD700
```

### Component Architecture

```mermaid
flowchart TB
    Main[main]

    subgraph Foundational_Functions
        CheckJq[check_jq_dependency]
        SaveSettings[save_settings]
        Backup[backup_settings]
    end

    subgraph Scope_Management
        GetGlobalPath[get_global_config_path]
        GetProjectPath[get_project_config_path]
        ValidateWritable[validate_writable]
        PromptScope[prompt_scope_selection]
    end

    subgraph Provider_Selection
        GetProviderUrl[get_provider_base_url]
        PromptProvider[prompt_provider_selection]
    end

    subgraph Configuration_Prompts
        ReadValues[read_existing_values]
        PromptAuth[prompt_auth_token]
        PromptUrl[prompt_base_url]
        PromptModels[prompt_all_models]
    end

    subgraph Display_Helper
        DisplayConfig[display_current_config]
        PromptCreate[prompt_create_config]
        ShowHelp[show_help]
    end

    subgraph Signal_Cleanup
        Cleanup[cleanup]
        RestoreTerm[restore_terminal]
    end

    subgraph External_Dependencies
        Jq[jq CLI tool JSON processing]
    end

    subgraph Configuration_Storage
        GlobalConfig[~/.claude/settings.json]
        ProjectConfig[./.claude/settings.json]
    end

    Main --> CheckJq
    Main --> PromptScope
    Main --> PromptProvider
    Main --> PromptCreate
    Main --> PromptAuth
    Main --> PromptUrl
    Main --> PromptModels
    Main --> Backup
    Main --> SaveSettings
    Main --> ShowHelp

    PromptScope --> ValidateWritable
    ValidateWritable --> GlobalConfig
    ValidateWritable --> ProjectConfig

    PromptProvider --> GetProviderUrl
    GetProviderUrl --> GlobalConfig
    GetProviderUrl --> ProjectConfig

    ReadValues --> GlobalConfig
    ReadValues --> ProjectConfig
    SaveSettings --> GlobalConfig
    SaveSettings --> ProjectConfig
    Backup --> GlobalConfig
    Backup --> ProjectConfig
    DisplayConfig --> GlobalConfig
    DisplayConfig --> ProjectConfig

    CheckJq --> Jq
    SaveSettings --> Jq
    ReadValues --> Jq
    DisplayConfig --> Jq

    Cleanup -.-> Main
    RestoreTerm -.-> Main
```

### Data Flow: Configuration Merging

```mermaid
flowchart LR
    subgraph Existing_Config
        Existing[Read from settings.json]
        Existing --> Parse[JSON parse via jq]
        Parse --> ExtEnv[Extract .env section]
    end

    subgraph New_Values
        Token[ANTHROPIC_AUTH_TOKEN]
        Url[ANTHROPIC_BASE_URL]
        Models[Three model names]
    end

    Existing -->|If valid| Merge{Merge strategy}
    Existing -.->|If invalid| CreateNew[Create new JSON structure]

    Merge --> OverrideEnv[Replace .env with new values Keep other top-level keys]
    CreateNew --> OverrideEnv

    OverrideEnv --> Write[Write to file]
    Write --> Result

    Token --> OverrideEnv
    Url --> OverrideEnv
    Models --> OverrideEnv
```

### State Machine: Configuration Scope & Provider

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> ScopeSelected: User runs script
    ScopeSelected --> GlobalScope: Choose 1
    ScopeSelected --> ProjectScope: Choose 2

    GlobalScope --> ProviderSelected: FILE_CONFIG validated
    ProjectScope --> ProviderSelected: FILE_CONFIG validated

    ProviderSelected --> OpenRouter: Choose 1
    ProviderSelected --> Ollama: Choose 2
    ProviderSelected --> Custom: Choose 3

    OpenRouter --> LoadingConfig: Load existing values
    Ollama --> LoadingConfig: Load existing values
    Custom --> LoadingConfig: Load existing values

    LoadingConfig --> DisplayingCurrent: Config exists
    LoadingConfig --> CreatingConfig: Config does not exist

    DisplayingCurrent --> CollectingAuth: User confirms
    CreatingConfig --> CollectingAuth: User confirms

    CollectingAuth --> CollectingURL: Valid token
    CollectingAuth --> CollectingAuth: Invalid or empty token

    OpenRouter --> CollectingURL: URL set automatically
    Ollama --> CollectingURL: Show default, allow edit
    Custom --> CollectingURL: Prompt for URL

    CollectingURL --> CollectingModels: Valid URL
    CollectingURL --> CollectingURL: Empty URL

    CollectingModels --> Saving: All models collected
    CollectingModels --> CollectingModels: Empty model (allowed)

    Saving --> Complete: Write successful
    Saving --> Error: Write failed

    Complete --> [*]
    Error --> [*]
```

---

**Legend:**
- **Rounded rectangles**: Processes/functions
- **Diamonds**: Decision points
- **Hexagons**: User interactions
- **Cylinders**: Data storage (files)
- **Arrows**: Control flow/data flow
- **Dashed arrows**: Dependencies/associations

## 💡 Examples

```bash
claude-custom
# → Scope: Global
# → Provider: OpenRouter
# → API token: (enter your OpenRouter key)
# → Models: (accept defaults or customize)
```

### Configure Ollama for a specific project

```bash
cd /path/to/project
claude-custom
# → Scope: Project
# → Provider: Ollama
# → Uses http://localhost:11434 automatically
```

### Switch providers

Just run `claude-custom` again and select a different provider. The old configuration is preserved as a backup.

## 🔧 Troubleshooting

**"jq is required but not installed"**
→ Install jq using the instructions above for your operating system.

**"Cannot create directory/file"**
→ Check write permissions for the target location (`~/.claude/` for global, current directory for project).

**"Invalid or missing settings.json"**
→ The tool will create a new valid configuration. If you have an existing corrupted file, it will be backed up before being replaced.

**Changes not taking effect**
→ Restart Claude Code after running `claude-custom`.

## 📄 License

See the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Arif Ariyan**  
[beetlix.com](https://beetlix.com) · [riffcompiler.com](https://riffcompiler.com)
