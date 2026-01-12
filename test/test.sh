#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nix

# Unit test runner for nix tests
# Run all test files in the test directory and report results

# Color codes for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Track overall status
overall_status=0
test_count=0
passed_count=0
failed_count=0

# Array of test files to run
# Add new test files here as they are created
test_files=(
  "addresses-test.nix"
)

# Function to run a single test file
run_test() {
  local test_file="$1"
  local test_path="/etc/nixos/test/${test_file}"

  echo -e "${YELLOW}Running${NC} ${test_file}..."

  if nix-instantiate --eval --expr "import ${test_path}" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} ${test_file} passed"
    passed_count=$((passed_count + 1))
  else
    echo -e "${RED}✗${NC} ${test_file} failed"
    failed_count=$((failed_count + 1))
    overall_status=1
  fi
  test_count=$((test_count + 1))
}

# Main test runner
main() {
  echo "Running Nix unit tests..."

  for test_file in "${test_files[@]}"; do
    run_test "$test_file"
  done

  echo ""
  echo "Test summary:"
  echo "  Total: ${test_count}"
  echo -e "  ${GREEN}Passed${NC}: ${passed_count}"
  if [ "${failed_count}" -gt 0 ]; then
    echo -e "  ${RED}Failed${NC}: ${failed_count}"
  fi

  if [ "${overall_status}" -eq 0 ]; then
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
  else
    echo ""
    echo -e "${RED}Some tests failed!${NC}"
  fi

  return "${overall_status}"
}

main "$@"
