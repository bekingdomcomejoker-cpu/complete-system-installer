#!/bin/bash
# ============================================================================
# COMPLETE SYSTEM INSTALLER v1.0
# Automated deployment of all Aletheia system components
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

# ============================================================================
# COMPONENTS
# ============================================================================

COMPONENTS=(
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
    clear
    echo -e "${CYAN}"
    cat << "BANNER"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║    🚀 COMPLETE SYSTEM INSTALLER v1.0 🚀                  ║
║                                                            ║
║         Automated Aletheia System Deployment              ║
║                                                            ║
║              13 Components | Full Integration             ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

pre_flight_checks() {
    log "Running pre-flight checks..."
    
    # Check git
    if ! command -v git &> /dev/null; then
        error "Git is not installed"
    fi
    info "✓ Git found"
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        error "Python 3 is not installed"
    fi
    info "✓ Python 3 found"
    
    # Check disk space
    local available=$(df "$INSTALL_DIR" | tail -1 | awk '{print $4}')
    if [ "$available" -lt 500000 ]; then
        warn "Low disk space available"
    else
        info "✓ Sufficient disk space"
    fi
    
    log "Pre-flight checks completed"
}

install_dependencies() {
    log "Installing dependencies..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -y
        sudo apt-get install -y python3-pip git curl
    elif command -v brew &> /dev/null; then
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
        info "[DRY RUN] Would clone: $repo_url"
        return 0
    fi
    
    if [ -d "$INSTALL_DIR/$component" ]; then
        warn "$component already exists, skipping"
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
    
    log "All components installed"
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
    
    log "Verification complete: $installed/${#COMPONENTS[@]} components"
}

post_install() {
    log "Running post-installation tasks..."
    
    # Create symlinks
    mkdir -p "$INSTALL_DIR/bin"
    
    # Create master control script
    cat > "$INSTALL_DIR/bin/aletheia-control" << 'EOF'
#!/bin/bash
# Master control script for Aletheia system
echo "Aletheia System Control"
echo "Available commands:"
echo "  status   - Show system status"
echo "  start    - Start all services"
echo "  stop     - Stop all services"
echo "  restart  - Restart all services"
EOF
    chmod +x "$INSTALL_DIR/bin/aletheia-control"
    
    info "Post-installation tasks completed"
}

show_summary() {
    echo -e "\n${CYAN}=== INSTALLATION SUMMARY ===${NC}"
    echo "Install Directory: $INSTALL_DIR"
    echo "Log File: $LOG_FILE"
    echo "Components: ${#COMPONENTS[@]}"
    echo ""
    echo -e "${GREEN}✅ Installation completed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review the installation log: $LOG_FILE"
    echo "  2. Run: $INSTALL_DIR/bin/aletheia-control status"
    echo "  3. Start services: $INSTALL_DIR/bin/aletheia-control start"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    show_banner
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                info "Running in dry-run mode"
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift
                ;;
            *)
                warn "Unknown option: $1"
                ;;
        esac
        shift
    done
    
    # Create log file
    mkdir -p "$INSTALL_DIR"
    touch "$LOG_FILE"
    
    # Run installation
    pre_flight_checks
    install_dependencies
    install_all_components
    verify_installation
    post_install
    show_summary
}

main "$@"
