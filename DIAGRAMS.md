### Flow Diagram

```mermaid
flowchart TD
    Start([User runs bin/claude-custom]) --> CheckArgs{Command-line arguments?}

    CheckArgs -->|--help| ShowHelp[Show help & exit]
    CheckArgs -->|--version| ShowVersion[Show version & exit]
    CheckArgs -->|--reset| ResetFlow[Reset flow]
    CheckArgs -->|None| MainFlow[Main execution flow]

    ResetFlow --> CheckJqReset{Check jq dependency}
    CheckJqReset -->|Not installed| JqError[Error & exit]
    CheckJqReset -->|Installed| PromptResetScope[Prompt for scope]
    PromptResetScope --> GetResetScope{User choice}
    GetResetScope -->|1 Global| SetResetGlobal[Set RESET_SCOPE=global]
    GetResetScope -->|2 Project| SetResetProject[Set RESET_SCOPE=project]
    SetResetGlobal --> CheckResetConfig{Config exists?}
    SetResetProject --> CheckResetConfig
    CheckResetConfig -->|No| NoConfig[No config to reset]
    CheckResetConfig -->|Yes| DisplayResetInfo[Display current config]
    DisplayResetInfo --> ConfirmReset{Prompt confirm?}
    ConfirmReset -->|No| AbortReset[Abort]
    ConfirmReset -->|Yes| CreateResetBackup[Create backup]
    CreateResetBackup --> PerformReset[Remove claude-custom keys]
    PerformReset --> ResetSuccess[Success message]
    NoConfig --> End
    AbortReset --> End
    ResetSuccess --> End([Exit])

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
    style ResetFlow fill:#E6E6FA
    style ResetSuccess fill:#ADD8E6
    style NoConfig fill:#FFD700
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

    subgraph Reset_Management
        HandleReset[handle_reset]
        PromptResetScope[prompt_reset_scope]
        CheckConfigExists[check_config_exists]
        PromptResetConfirm[prompt_reset_confirmation]
        BackupClaudeConfig[backup_claude_config]
        ResetConfig[reset_config]
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
    Main --> HandleReset

    PromptScope --> ValidateWritable
    ValidateWritable --> GlobalConfig
    ValidateWritable --> ProjectConfig

    HandleReset --> PromptResetScope
    PromptResetScope --> CheckConfigExists
    CheckConfigExists --> PromptResetConfirm
    PromptResetConfirm --> BackupClaudeConfig
    BackupClaudeConfig --> ResetConfig --> GetProviderUrl
    GetProvider

    PromptProviderUrl --> GlobalConfig
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

### Data Flow: Configuration Reset

```mermaid
flowchart LR
    subgraph User_Input
        RunReset[User runs: claude-custom --reset]
        SelectScope[Select: Global or Project]
        Confirm[Confirm reset]
    end

    subgraph Validation
        CheckJq{Check jq installed?}
        CheckConfig{Config exists?}
    end

    subgraph Reset_Process
        BuildFilter[Build jq filter to delete keys]
        Backup[Create backup of keys]
        RemoveKeys[Remove claude-custom keys]
    end

    subgraph Keys_To_Remove
        AuthToken[ANTHROPIC_AUTH_TOKEN]
        ApiKey[ANTHROPIC_API_KEY]
        BaseUrl[ANTHROPIC_BASE_URL]
        Sonnet[ANTHROPIC_DEFAULT_SONNET_MODEL]
        Opus[ANTHROPIC_DEFAULT_OPUS_MODEL]
        Haiku[ANTHROPIC_DEFAULT_HAIKU_MODEL]
    end

    RunReset --> CheckJq
    CheckJq -->|No| JqError[Error: jq required]
    CheckJq -->|Yes| SelectScope
    SelectScope --> CheckConfig
    CheckConfig -->|No| NoConfig[Nothing to reset]
    CheckConfig -->|Yes| Confirm
    Confirm -->|No| Abort[Abort]
    Confirm -->|Yes| BuildFilter
    BuildFilter --> Backup
    Backup --> RemoveKeys

    AuthToken -.-> RemoveKeys
    ApiKey -.-> RemoveKeys
    BaseUrl -.-> RemoveKeys
    Sonnet -.-> RemoveKeys
    Opus -.-> RemoveKeys
    Haiku -.-> RemoveKeys

    RemoveKeys --> Success[Success]
    NoConfig --> Success
    Abort --> End

    style RunReset fill:#E6E6FA
    style ResetProcess fill:#E6E6FA
    style Success fill:#ADD8E6
    style JqError fill:#FFCCCB
```

### State Machine: Configuration Scope & Provider

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> CheckArgs: User runs script
    CheckArgs --> Help: --help
    CheckArgs --> Version: --version
    CheckArgs --> ResetFlow: --reset
    CheckArgs --> ScopeSelected: No args

    Help --> [*]
    Version --> [*]

    ResetFlow --> ResetScope: Valid jq
    ResetScope --> ResetGlobal: Choose 1
    ResetScope --> ResetProject: Choose 2
    ResetGlobal --> CheckConfig: Exists
    ResetProject --> CheckConfig
    CheckConfig --> NoConfig: Not exists
    CheckConfig --> ConfirmReset: Exists
    NoConfig --> [*]
    ConfirmReset --> AbortReset: No
    ConfirmReset --> CreateBackup: Yes
    AbortReset --> [*]
    CreateBackup --> PerformReset: Confirmed
    PerformReset --> ResetComplete: Success
    ResetComplete --> [*]

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
