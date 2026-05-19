#!/bin/bash
# ============================================================================
# COMPLETE SYSTEM INSTALLER v1.1
# Automated deployment of Aletheia/Omega system components
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[INSTALLER]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

INSTALL_DIR="${INSTALL_DIR:-.}"
LOG_FILE="$INSTALL_DIR/installation.log"
DRY_RUN=false
INSTALL_DEPS=true

# ============================================================================
# COMPONENTS
# ============================================================================

COMPONENTS=(
    "omega-os-monolith"
    "omega-os-v3"
    "merkabah-engine"
    "merkabah-integrated"
    "aletheia-unified-system"
    "multi-llm-orchestrator"
    "merkabah-dashboard"
    "mega-engine-repair"
    "termux-merkabah-suite"
    "python-hybrid-interpreter"
    "dominique-unified-system"
    "ultimate-merkabah-kernel"
    "termux-system-scanner-advanced"
    "llm-placement-strategy"
)

# ============================================================================
# FUNCTIONS
# ============================================================================

show_banner() {
    if command -v clear >/dev/null 2>&1; then clear; fi
    echo -e "${CYAN}"
    cat << "BANNER"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║    🚀 COMPLETE SYSTEM INSTALLER v1.1 🚀                  ║
║                                                            ║
║        Aletheia / Omega Component Deployment              ║
║                                                            ║
║          Monolith Control Plane + Runtime Stack           ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

pre_flight_checks() {
    log "Running pre-flight checks..."

    if ! command -v git >/dev/null 2>&1; then
        error "Git is not installed"
    fi
    info "✓ Git found"

    if ! command -v python3 >/dev/null 2>&1; then
        error "Python 3 is not installed"
    fi
    info "✓ Python 3 found"

    local available
    available=$(df "$INSTALL_DIR" | tail -1 | awk '{print $4}')
    if [ "$available" -lt 500000 ]; then
        warn "Low disk space available"
    else
        info "✓ Sufficient disk space"
    fi

    log "Pre-flight checks completed"
}

install_dependencies() {
    if [ "$INSTALL_DEPS" = false ]; then
        info "Skipping dependency installation (--no-deps)"
        return 0
    fi

    log "Installing dependencies..."

    if command -v pkg >/dev/null 2>&1; then
        pkg update -y
        pkg install -y python git curl
    elif command -v apt-get >/dev/null 2>&1; then
        if command -v sudo >/dev/null 2>&1; then
            sudo apt-get update -y
            sudo apt-get install -y python3-pip git curl
        else
            apt-get update -y
            apt-get install -y python3-pip git curl
        fi
    elif command -v brew >/dev/null 2>&1; then
        brew install python3 git curl
    else
        warn "Package manager not found, skipping dependency installation"
    fi

    log "Dependencies installed"
}

install_component() {
    local component=$1
    local repo_url="https://github.com/bekingdomcomejoker-cpu/$component.git"

    info "Installing $component..."

    if [ "$DRY_RUN" = true ]; then
        info "[DRY RUN] Would clone: $repo_url -> $INSTALL_DIR/$component"
        return 0
    fi

    if [ -d "$INSTALL_DIR/$component/.git" ]; then
        warn "$component already exists, fetching latest metadata only"
        git -C "$INSTALL_DIR/$component" status --short 2>&1 | tee -a "$LOG_FILE" || true
        return 0
    fi

    if [ -d "$INSTALL_DIR/$component" ]; then
        warn "$component directory exists but is not a git checkout, skipping"
        return 0
    fi

    git clone "$repo_url" "$INSTALL_DIR/$component" 2>&1 | tee -a "$LOG_FILE"

    info "✓ $component installed"
}

install_all_components() {
    log "Installing all components..."

    local total=${#COMPONENTS[@]}
    local current=1

    for component in "${COMPONENTS[@]}"; do
        echo -e "\n${CYAN}[$current/$total] Installing $component...${NC}"
        install_component "$component"
        ((current++))
    done

    log "All components processed"
}

verify_installation() {
    log "Verifying installation..."

    local installed=0
    for component in "${COMPONENTS[@]}"; do
        if [ -d "$INSTALL_DIR/$component" ]; then
            info "✓ $component verified"
            ((installed++))
        else
            warn "✗ $component not found"
        fi
    done

    if [ -f "$INSTALL_DIR/omega-os-monolith/CONTROL_PLANE/omega_terminal_router_http.py" ]; then
        info "✓ omega-os-monolith control-plane router found"
    else
        warn "omega-os-monolith control-plane router not found"
    fi

    if [ -f "$INSTALL_DIR/omega-os-monolith/CONTROL_PLANE/start_local_llama.sh" ]; then
        info "✓ omega-os-monolith local llama control script found"
    else
        warn "omega-os-monolith local llama control script not found"
    fi

    log "Verification complete: $installed/${#COMPONENTS[@]} components"
}

post_install() {
    log "Running post-installation tasks..."

    mkdir -p "$INSTALL_DIR/bin"

    cat > "$INSTALL_DIR/bin/aletheia-control" << EOF
#!/bin/bash
set -euo pipefail
ROOT="\${ALETHEIA_ROOT:-$INSTALL_DIR}"
MONOLITH="\${ROOT}/omega-os-monolith"
CONTROL="\${MONOLITH}/CONTROL_PLANE"

case "\${1:-status}" in
  status)
    echo "Aletheia/Omega System Control"
    echo "Root: \${ROOT}"
    echo "Monolith: \${MONOLITH}"
    [ -f "\${CONTROL}/omega_terminal_router_http.py" ] && echo "[+] router: \${CONTROL}/omega_terminal_router_http.py" || echo "[-] router missing"
    [ -f "\${CONTROL}/start_local_llama.sh" ] && echo "[+] llama control: \${CONTROL}/start_local_llama.sh" || echo "[-] llama control missing"
    if [ -f "\${CONTROL}/start_local_llama.sh" ]; then
      bash "\${CONTROL}/start_local_llama.sh" status 8080 || true
    fi
    ;;
  dry-run)
    bash "\${CONTROL}/start_local_llama.sh" dry-run "\${2:-8080}"
    ;;
  healthcheck)
    python3 "\${CONTROL}/omega_terminal_router_http.py" healthcheck
    ;;
  oroute)
    shift
    python3 "\${CONTROL}/omega_terminal_router_http.py" "\$@"
    ;;
  *)
    echo "Usage: aletheia-control status|dry-run [port]|healthcheck|oroute <route> <prompt>"
    exit 1
    ;;
esac
EOF
    chmod +x "$INSTALL_DIR/bin/aletheia-control"

    if [ "$DRY_RUN" = false ]; then
        chmod +x "$INSTALL_DIR/omega-os-monolith/CONTROL_PLANE/start_local_llama.sh" 2>/dev/null || true
        chmod +x "$INSTALL_DIR/omega-os-monolith/CONTROL_PLANE/omega_terminal_router_http.py" 2>/dev/null || true
    fi

    info "Post-installation tasks completed"
}

show_summary() {
    echo -e "\n${CYAN}=== INSTALLATION SUMMARY ===${NC}"
    echo "Install Directory: $INSTALL_DIR"
    echo "Log File: $LOG_FILE"
    echo "Components: ${#COMPONENTS[@]}"
    echo ""
    echo -e "${GREEN}✅ Installation completed or dry-run completed.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review the installation log: $LOG_FILE"
    echo "  2. Run: $INSTALL_DIR/bin/aletheia-control status"
    echo "  3. Dry-run local model discovery: $INSTALL_DIR/bin/aletheia-control dry-run 8080"
    echo "  4. Healthcheck after local server start: $INSTALL_DIR/bin/aletheia-control healthcheck"
    echo ""
}

usage() {
    cat << TXT
Usage: $0 [--dry-run] [--install-dir PATH] [--no-deps]

Options:
  --dry-run          Print clone/install actions without cloning.
  --install-dir PATH Install into PATH.
  --no-deps          Skip package manager dependency installation.
TXT
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    show_banner

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                info "Running in dry-run mode"
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                LOG_FILE="$INSTALL_DIR/installation.log"
                shift
                ;;
            --no-deps)
                INSTALL_DEPS=false
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                warn "Unknown option: $1"
                ;;
        esac
        shift
    done

    mkdir -p "$INSTALL_DIR"
    touch "$LOG_FILE"

    pre_flight_checks
    install_dependencies
    install_all_components
    verify_installation
    post_install
    show_summary
}

main "$@"
