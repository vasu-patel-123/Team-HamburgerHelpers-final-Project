#!/bin/bash

set -e

# Define colors for echo
BLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help message
function show_help {
  echo -e "${BLUE}Taskii Project Maintenance Script${NC}"
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -q, --quick      Skip Dart fixes, format, pod update, FlutterFire configure, analyze, and tests"
  echo "      --no-ios     Skip all iOS pod-related steps"
  echo "  -h, --help       Show this help message and exit"
  echo ""
  echo "Examples:"
  echo "  $0                # Run full maintenance"
  echo "  $0 --quick        # Run in quick mode"
  echo "  $0 --no-ios       # Skip iOS pod steps"
  echo "  $0 -q --no-ios    # Quick mode, no iOS steps"
}

# Parse arguments
SKIP_IOS=false
QUICK_MODE=false
for arg in "$@"; do
  if [[ "$arg" == "--no-ios" ]]; then
    SKIP_IOS=true
  fi
  if [[ "$arg" == "--quick" || "$arg" == "-q" ]]; then
    QUICK_MODE=true
  fi
  if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
    show_help
    exit 0
  fi
done

# Calculate total steps dynamically
TOTAL_STEPS=2 # flutter clean, build_runner

if [[ "$QUICK_MODE" == false ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 3)) # dart fix dry, dart fix apply, dart format
fi

# iOS steps (only on macOS and not --no-ios)
if [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == false ]]; then
  if [[ "$QUICK_MODE" == false ]]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 4)) # pod cache clean, flutter pub get, pod update, pod install
  else
    TOTAL_STEPS=$((TOTAL_STEPS + 2)) # remove Pods/Podfile.lock, pod install
  fi
fi

TOTAL_STEPS=$((TOTAL_STEPS + 1)) # flutter re-clean

if [[ "$QUICK_MODE" == false ]]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 3)) # flutterfire configure, analyze, tests
fi

STEP=1

# Error handler function
function handle_error {
  echo -e "${RED}❌ Error on line $1: $2${NC}"
  echo -e "${RED}Script failed at step $STEP.${NC}"
  exit 1
}

# Trap errors and call handler
trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

echo -e "${BLUE}"
echo "=============================================="
echo "     🛠️  Taskii Project Maintenance Script    "
echo "=============================================="
if [[ "$QUICK_MODE" == true ]]; then
  echo "             (Quick Mode Enabled)"
fi
if [[ "$SKIP_IOS" == true ]]; then
  echo "             (iOS Steps Skipped)"
fi
echo -e "${NC}"

# Check for required tools
REQUIRED_TOOLS=(flutter dart)
if [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == false ]]; then
  REQUIRED_TOOLS+=(pod)
fi
for cmd in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${RED}Error: $cmd is not installed or not in PATH.${NC}"
    exit 1
  fi
done

# Ensure script is run from the 'taskii' directory
if [ "$(basename "$PWD")" != "taskii" ]; then
  if [ -d "taskii" ]; then
    echo -e "${BLUE}Detected project root. Changing directory to 'taskii'.${NC}"
    cd taskii
  else
    echo -e "${RED}Error: Please run this script from the project root or 'taskii' directory.${NC}"
    exit 1
  fi
fi

# Step numbers and timing
function run_step {
  local desc="$1"
  shift
  echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}]${NC} ${BLUE}${desc}${NC}"
  local start_time=$(date +%s)
  "$@"
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  echo -e "${GREEN}✔ Completed in ${duration}s${NC}\n"
  STEP=$((STEP+1))
}

run_step "Flutter clean" bash -c '
  FLUTTER_CLEAN_OUTPUT=$(flutter clean 2>&1) || true
  if echo "$FLUTTER_CLEAN_OUTPUT" | grep -q "not a Flutter project"; then
    echo -e "${RED}Error: This is not a Flutter project directory. Please run the script in your Flutter project root or '\''taskii'\'' directory.${NC}"
    exit 1
  fi
  echo "$FLUTTER_CLEAN_OUTPUT"
'

if [[ "$QUICK_MODE" == false ]]; then
  run_step "Dart fix (dry run)" dart fix --dry-run
  run_step "Dart fix (apply)" dart fix --apply
fi

run_step "Build runner for tests (delete conflicting outputs)" dart run build_runner build --delete-conflicting-outputs

if [[ "$QUICK_MODE" == false ]]; then
  run_step "Dart format" dart format .
fi

if [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == false ]]; then
  if [[ "$QUICK_MODE" == false ]]; then
    run_step "iOS: Pod cache clean, remove Pods and Podfile.lock" bash -c '
      cd ios || { echo -e "${RED}Failed to cd into ios directory.${NC}"; exit 1; }
      pod cache clean --all
      rm -rf Pods Podfile.lock
      cd ..
    '
    run_step "iOS: Flutter pub get" bash -c 'cd ios && flutter pub get && cd ..'
    run_step "iOS: Pod update" bash -c 'cd ios && pod update && cd ..'
  else
    run_step "iOS: Remove Pods and Podfile.lock" bash -c '
      cd ios || { echo -e "${RED}Failed to cd into ios directory.${NC}"; exit 1; }
      rm -rf Pods Podfile.lock
      cd ..
    '
  fi
  run_step "iOS: Pod install" bash -c 'cd ios && pod install && cd ..'
fi

run_step "Flutter re-clean" flutter clean

if [[ "$QUICK_MODE" == false ]]; then
  run_step "Reconfigure FlutterFire" flutterfire configure
  run_step "Analyze Project" flutter analyze
  run_step "Run tests" bash -c '
  if [ -d "test" ]; then
    echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}]${NC} ${BLUE}Running tests...${NC}"
    flutter test --coverage
  else
    echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}]${NC} ${BLUE}No test directory found. Skipping tests.${NC}"
  fi
  '
fi
echo -e "${GREEN}=============================================="
echo -e "✅  All maintenance steps completed successfully!"
echo -e "==============================================${NC}"