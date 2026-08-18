AI_CONFIG_DIR="${AI_CONFIG_DIR:-$HOME/projects/personal/agent-forge}"

# WIP skill/memory command family (skill-new, skill-encrypt, memory-graduate,
# etc.), on PATH so `skill<TAB>` / `memory<TAB>` tab-completes all six verbs.
export PATH="$AI_CONFIG_DIR/shared/tools:$PATH"

# Claude Code aliases
alias cld="claude --dangerously-skip-permissions"
alias cldr="cld --resume"
alias cldm="claude-monitor"

# Antigravity CLI aliases
alias aggy="agy --dangerously-skip-permissions"
alias aggyr="aggy --continue"

# Codex CLI aliases
alias chat="codex --dangerously-bypass-approvals-and-sandbox"
alias chatr="codex resume --last --dangerously-bypass-approvals-and-sandbox"

# Copilot CLI aliases
alias pilot="copilot --allow-all"
alias pilotr="copilot --continue --allow-all"
