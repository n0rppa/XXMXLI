# Test log
test_log "INFO" "Testing function: log"
test_function_exists "log"
test_function_syntax "log"
echo ""

# Test success
test_log "INFO" "Testing function: success"
test_function_exists "success"
test_function_syntax "success"
echo ""

# Test error
test_log "INFO" "Testing function: error"
test_function_exists "error"
test_function_syntax "error"
echo ""

# Test warn
test_log "INFO" "Testing function: warn"
test_function_exists "warn"
test_function_syntax "warn"
echo ""

# Test info
test_log "INFO" "Testing function: info"
test_function_exists "info"
test_function_syntax "info"
echo ""

# Test show_banner
test_log "INFO" "Testing function: show_banner"
test_function_exists "show_banner"
test_function_syntax "show_banner"
echo ""

# Test show_interactive_menu
test_log "INFO" "Testing function: show_interactive_menu"
test_function_exists "show_interactive_menu"
test_function_syntax "show_interactive_menu"
echo ""

# Test check_environment
test_log "INFO" "Testing function: check_environment"
test_function_exists "check_environment"
test_function_syntax "check_environment"
echo ""

# Test full_health_check
test_log "INFO" "Testing function: full_health_check"
test_function_exists "full_health_check"
test_function_syntax "full_health_check"
echo ""

# Test directory_check
test_log "INFO" "Testing function: directory_check"
test_function_exists "directory_check"
test_function_syntax "directory_check"
echo ""

# Test server_api_check
test_log "INFO" "Testing function: server_api_check"
test_function_exists "server_api_check"
test_function_syntax "server_api_check"
echo ""

# Test data_validation
test_log "INFO" "Testing function: data_validation"
test_function_exists "data_validation"
test_function_syntax "data_validation"
echo ""

# Test github_pages_check
test_log "INFO" "Testing function: github_pages_check"
test_function_exists "github_pages_check"
test_function_syntax "github_pages_check"
echo ""

# Test performance_analysis
test_log "INFO" "Testing function: performance_analysis"
test_function_exists "performance_analysis"
test_function_syntax "performance_analysis"
echo ""

# Test security_check
test_log "INFO" "Testing function: security_check"
test_function_exists "security_check"
test_function_syntax "security_check"
echo ""

# Test generate_health_report
test_log "INFO" "Testing function: generate_health_report"
test_function_exists "generate_health_report"
test_function_syntax "generate_health_report"
echo ""

# Test show_help
test_log "INFO" "Testing function: show_help"
test_function_exists "show_help"
test_function_syntax "show_help"
echo ""

# Test directory_check_silent
test_log "INFO" "Testing function: directory_check_silent"
test_function_exists "directory_check_silent"
test_function_syntax "directory_check_silent"
echo ""

# Test server_check_silent
test_log "INFO" "Testing function: server_check_silent"
test_function_exists "server_check_silent"
test_function_syntax "server_check_silent"
echo ""

# Test api_check_silent
test_log "INFO" "Testing function: api_check_silent"
test_function_exists "api_check_silent"
test_function_syntax "api_check_silent"
echo ""

# Test data_validation_silent
test_log "INFO" "Testing function: data_validation_silent"
test_function_exists "data_validation_silent"
test_function_syntax "data_validation_silent"
echo ""

# Test github_pages_check_silent
test_log "INFO" "Testing function: github_pages_check_silent"
test_function_exists "github_pages_check_silent"
test_function_syntax "github_pages_check_silent"
echo ""

# Test performance_check_silent
test_log "INFO" "Testing function: performance_check_silent"
test_function_exists "performance_check_silent"
test_function_syntax "performance_check_silent"
echo ""

# Test security_check_silent
test_log "INFO" "Testing function: security_check_silent"
test_function_exists "security_check_silent"
test_function_syntax "security_check_silent"
echo ""

# Test exit_program
test_log "INFO" "Testing function: exit_program"
test_function_exists "exit_program"
test_function_syntax "exit_program"
echo ""

# Test main
test_log "INFO" "Testing function: main"
test_function_exists "main"
test_function_syntax "main"
echo ""

# Test Summary
echo "📊 Test Summary"
echo "=============="
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"

if [[ $FAILED_TESTS -gt 0 ]]; then
    echo ""
    echo "🚨 Some tests failed. Check the output above for details."
    exit 1
else
    echo ""
    echo "✅ All tests passed!"
    exit 0
fi
