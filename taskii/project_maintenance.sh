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
  echo "  -q, --quick      Skip Dart fixes, format, pod update, flutterfire configure --platforms=android,ios,macos,windows --project=taskii-bf674 --yes, analyze, and tests"
  echo "      --no-ios     Skip all iOS pod-related steps"
  echo "  -c, --clean      Only clean everything (including iOS pods), skip all other steps"
  echo "  -d, --debug      Print every command and its output"
  echo "  -h, --help       Show this help message and exit"
  echo ""
  echo "Examples:"
  echo "  $0                # Run full maintenance"
  echo "  $0 --quick        # Run in quick mode"
  echo "  $0 --no-ios       # Skip iOS pod steps"
  echo "  $0 -q --no-ios    # Quick mode, no iOS steps"
  echo "  $0 -d             # Debug mode"
}

# Parse arguments
SKIP_IOS=false
QUICK_MODE=false
DEBUG_MODE=false
CLEAN_ONLY=false
for arg in "$@"; do
  if [[ "$arg" == "--no-ios" ]]; then
    SKIP_IOS=true
  fi
  if [[ "$arg" == "--quick" || "$arg" == "-q" ]]; then
    QUICK_MODE=true
  fi
  if [[ "$arg" == "--debug" || "$arg" == "-d" ]]; then
    DEBUG_MODE=true
  fi
  if [[ "$arg" == "--clean" || "$arg" == "-c" ]]; then
    CLEAN_ONLY=true
  fi
  if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
    show_help
    exit 0
  fi
done

if [[ "$DEBUG_MODE" == true ]]; then
  set -x
fi

# Define run_step function BEFORE any use
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
# TODO: Add a check for gradle and implement gradle functions
function check_gradle {
  if ! command -v gradle &> /dev/null; then
    echo -e "${RED}Error: Gradle is not installed or not in PATH.${NC}"
    exit 1
  fi
}
#check_gradle

# Calculate total steps dynamically
if [[ "$CLEAN_ONLY" == true ]]; then
  # Only cleaning: Flutter clean + (optional) iOS pod clean
  if [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == false ]]; then
    TOTAL_STEPS=4  # flutter clean, remove Pods/Podfile.lock, flutter pub get, pod install
  else
    TOTAL_STEPS=1  # flutter clean only
  fi
  # Add 1 for dart format
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
  STEP=1
  echo -e "${BLUE}Cleaning project...${NC}"
  run_step "Flutter clean" flutter clean
  if [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == false ]]; then
    run_step "iOS: Remove Pods and Podfile.lock" bash -c "
      cd ios || { echo -e \"${RED}Failed to cd into ios directory.${NC}\"; exit 1; }
      rm -rf Pods Podfile.lock
      cd ..
    "
    run_step "iOS: Flutter pub get" bash -c 'cd ios && flutter pub get && cd ..'
    run_step "iOS: Pod install" bash -c 'cd ios && pod install && cd ..'
  fi
  run_step "Dart format" dart format .
  echo -e "${GREEN}=============================================="
  echo -e "✅  Clean completed successfully!"
  echo -e "${GREEN}==============================================${NC}"
  exit 0
else
  TOTAL_STEPS=1 # flutter clean

  if [[ "$QUICK_MODE" == false ]]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 1)) # build_runner
    TOTAL_STEPS=$((TOTAL_STEPS + 3)) # dart fix dry, dart fix apply, dart format
  fi

  # iOS steps (only on macOS and not --no-ios)
  if [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == false ]]; then
    if [[ "$QUICK_MODE" == false ]]; then
      TOTAL_STEPS=$((TOTAL_STEPS + 4)) # pod cache clean, flutter pub get, pod update, pod install
    else
      TOTAL_STEPS=$((TOTAL_STEPS + 3)) # remove Pods/Podfile.lock, flutter pub get, pod install
    fi
  fi

  TOTAL_STEPS=$((TOTAL_STEPS + 1)) # flutter re-clean

  if [[ "$QUICK_MODE" == false ]]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 3)) # flutterfire configure --platforms=android,ios,macos,windows --project=taskii-bf674 --yes, analyze, tests
  fi

  # Always add 1 for dart format at the end
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
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

# Output enabled modes
if [[ "$QUICK_MODE" == true || "$SKIP_IOS" == true || "$CLEAN_ONLY" == true || "$DEBUG_MODE" == true ]]; then
  echo "             Enabled Modes:"
  [[ "$QUICK_MODE" == true ]] && echo "               - Quick Mode"
  [[ "$SKIP_IOS" == true ]] && echo "               - iOS Steps Skipped"
  [[ "$CLEAN_ONLY" == true ]] && echo "               - Clean Only Mode"
  [[ "$CLEAN_ONLY" == true && "$QUICK_MODE" == true ]] && echo "               - Quick Clean Mode"
  [[ "$DEBUG_MODE" == true ]] && echo "               - Debug Mode"
fi

# Output platform info
if [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == false ]]; then
  echo "             Platform: macOS (iOS Steps Included)"
elif [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == true ]]; then
  echo "             Platform: macOS (iOS Steps Skipped)"
else
  echo "             Platform: Non-macOS"
fi

if [[ "$CLEAN_ONLY" == false ]]; then
  echo "             Full Maintenance Mode"
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
run_step "Flutter clean" bash -c '
  FLUTTER_CLEAN_OUTPUT=$(flutter clean 2>&1) || true
  if echo "$FLUTTER_CLEAN_OUTPUT" | grep -q "not a Flutter project"; then
    echo -e "${RED}Error: This is not a Flutter project directory. Please run the script in your Flutter project root or '\''taskii'\'' directory.${NC}"
    exit 1
  fi
  echo "$FLUTTER_CLEAN_OUTPUT"
'

if [[ "$OSTYPE" == "darwin"* && "$SKIP_IOS" == false ]]; then
  if [[ "$QUICK_MODE" == false ]]; then
    run_step "iOS: Pod cache clean, remove Pods and Podfile.lock" bash -c "
      cd ios || { echo -e \"${RED}Failed to cd into ios directory.${NC}\"; exit 1; }
      pod cache clean --all
      rm -rf Pods Podfile.lock
      cd ..
    "
    run_step "iOS: Flutter pub get" bash -c 'cd ios && flutter pub get && cd ..'
    run_step "iOS: Pod update" bash -c 'cd ios && pod update && cd ..'
    run_step "iOS: Pod install" bash -c 'cd ios && pod install && cd ..'
  else
    run_step "iOS: Remove Pods and Podfile.lock" bash -c '
      cd ios || { echo -e "${RED}Failed to cd into ios directory.${NC}"; exit 1; }
      rm -rf Pods Podfile.lock
      cd ..
    '
    run_step "iOS: Flutter pub get" bash -c 'cd ios && flutter pub get && cd ..'
    run_step "iOS: Pod install" bash -c 'cd ios && pod install && cd ..'
  fi
fi

run_step "Flutter re-clean" flutter clean

if [[ "$QUICK_MODE" == false ]]; then
  run_step "Reconfigure FlutterFire" flutterfire configure --platforms=android,ios,macos,windows --project=taskii-bf674 --yes
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

if [[ "$QUICK_MODE" == false ]]; then
  run_step "Dart fix (dry run)" dart fix --dry-run
  run_step "Dart fix (apply)" dart fix --apply
  run_step "Build runner for tests (delete conflicting outputs)" dart run build_runner build --delete-conflicting-outputs
fi
run_step "Dart format" dart format .
echo -e "${GREEN}=============================================="
echo -e "✅  All maintenance steps completed successfully!"
echo -e "==============================================${NC}"