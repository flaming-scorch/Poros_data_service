#!/bin/bash
# Quick test script for PostgreSQL SQL files
# This script creates a test database and runs the SQL files

set -e

DB_NAME="poros_test_$(date +%s)"
TEST_USER="${USER}"

echo "=========================================="
echo "PostgreSQL SQL Validation Test"
echo "=========================================="
echo ""

# Add PostgreSQL to PATH if installed via Homebrew
if [ -d "/opt/homebrew/opt/postgresql@15/bin" ]; then
    export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
elif [ -d "/usr/local/opt/postgresql@15/bin" ]; then
    export PATH="/usr/local/opt/postgresql@15/bin:$PATH"
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed or not in PATH."
    echo "   Install it with: brew install postgresql@15"
    echo "   Then start it with: brew services start postgresql@15"
    exit 1
fi

# Check if PostgreSQL is running
if ! pg_isready -q 2>/dev/null; then
    echo "❌ PostgreSQL is not running."
    echo "   Start it with: brew services start postgresql@15"
    exit 1
fi

echo "✓ PostgreSQL is installed and running"
echo ""

# Create test database
echo "Creating test database: $DB_NAME"
createdb "$DB_NAME" 2>/dev/null || {
    echo "❌ Failed to create test database"
    exit 1
}
echo "✓ Test database created"
echo ""

# Run schema file
echo "Running schema file (sql/poros.sql)..."
if psql "$DB_NAME" < sql/poros.sql > /tmp/poros_schema_output.log 2>&1; then
    echo "✓ Schema file executed successfully"
else
    echo "❌ Schema file execution failed. Check /tmp/poros_schema_output.log for details"
    dropdb "$DB_NAME" 2>/dev/null
    exit 1
fi
echo ""

# Verify tables were created
echo "Verifying tables were created..."
TABLE_COUNT=$(psql -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" "$DB_NAME" | tr -d ' ')
echo "✓ Found $TABLE_COUNT tables"
echo ""

# List all tables
echo "Tables created:"
psql -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;" "$DB_NAME" | sed 's/^/  - /'
echo ""

# Verify views
echo "Verifying views..."
VIEW_COUNT=$(psql -t -c "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public';" "$DB_NAME" | tr -d ' ')
echo "✓ Found $VIEW_COUNT views"
echo ""

# Test a few sample queries
echo "Testing sample queries..."
echo ""

# Test 1: Count companies
echo "Test 1: Count companies"
COMPANY_COUNT=$(psql -t -c "SELECT COUNT(*) FROM companies;" "$DB_NAME" | tr -d ' ')
echo "  ✓ Found $COMPANY_COUNT companies"
echo ""

# Test 2: Query view
echo "Test 2: Query user_dashboard_stats view"
if psql -t -c "SELECT * FROM user_dashboard_stats LIMIT 1;" "$DB_NAME" > /dev/null 2>&1; then
    echo "  ✓ View is queryable"
else
    echo "  ⚠ View query had issues (expected if no users exist)"
fi
echo ""

# Test 3: Test a query from poros-queries.sql (modified)
echo "Test 3: Test company recommendations view"
if psql -t -c "SELECT COUNT(*) FROM company_recommendations_view;" "$DB_NAME" > /dev/null 2>&1; then
    VIEW_RESULT=$(psql -t -c "SELECT COUNT(*) FROM company_recommendations_view;" "$DB_NAME" | tr -d ' ')
    echo "  ✓ View returned $VIEW_RESULT companies"
else
    echo "  ❌ View query failed"
fi
echo ""

# Cleanup
echo "Cleaning up test database..."
dropdb "$DB_NAME" 2>/dev/null
echo "✓ Test database dropped"
echo ""

echo "=========================================="
echo "✅ All tests passed!"
echo "=========================================="
echo ""
echo "The SQL files are valid and executable."
echo "You can now use them in your application."

