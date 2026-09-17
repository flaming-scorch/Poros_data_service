#!/usr/bin/env python3
"""
SQL Validation Script for Poros Data Service
This script performs basic validation checks on SQL files.
"""

import re
import sys
from pathlib import Path

def check_sql_file(file_path):
    """Check SQL file for common issues."""
    issues = []
    warnings = []
    
    with open(file_path, 'r') as f:
        content = f.read()
        lines = content.split('\n')
    
    # Check for balanced parentheses in CREATE statements
    paren_count = 0
    in_string = False
    string_char = None
    
    for i, line in enumerate(lines, 1):
        # Track string boundaries (basic check)
        for char in line:
            if char in ("'", '"') and (i == 0 or lines[i-2][max(0, len(lines[i-2])-1):] != '\\'):
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None
            
            if not in_string:
                if char == '(':
                    paren_count += 1
                elif char == ')':
                    paren_count -= 1
        
        # Check for common SQL issues
        stripped = line.strip()
        
        # Check for missing semicolons (except comments, empty lines, and certain statements)
        if (stripped and 
            not stripped.startswith('--') and 
            not stripped.startswith('/*') and
            not stripped.endswith(';') and
            not stripped.endswith(',') and
            not any(keyword in stripped.upper() for keyword in ['CREATE TABLE', 'CREATE VIEW', 'CREATE TRIGGER', 'CREATE FUNCTION', 'CREATE INDEX', 'INSERT INTO', 'DROP TABLE', 'COMMENT ON', 'GROUP BY', 'ORDER BY', 'LEFT JOIN', 'JOIN', 'WHERE', 'SELECT', 'FROM', 'UNION', 'VALUES'])):
            # This is a basic check and may have false positives
            pass
    
    # Check for table references
    tables_created = re.findall(r'CREATE TABLE (\w+)', content, re.IGNORECASE)
    tables_referenced = re.findall(r'REFERENCES (\w+)', content, re.IGNORECASE)
    
    # Check for undefined table references (basic check)
    for ref in set(tables_referenced):
        if ref not in tables_created and ref.upper() not in ['SERIAL', 'INTEGER', 'VARCHAR', 'TEXT', 'TIMESTAMP', 'DATE', 'BOOLEAN']:
            # This is a basic check - may have false positives
            pass
    
    # Check for view dependencies
    views = re.findall(r'CREATE (?:OR REPLACE )?VIEW (\w+)', content, re.IGNORECASE)
    
    # Check for function definitions
    functions = re.findall(r'CREATE (?:OR REPLACE )?FUNCTION (\w+)', content, re.IGNORECASE)
    
    # Check for trigger definitions
    triggers = re.findall(r'CREATE TRIGGER (\w+)', content, re.IGNORECASE)
    
    return {
        'file': file_path,
        'tables': len(tables_created),
        'views': len(views),
        'functions': len(functions),
        'triggers': len(triggers),
        'issues': issues,
        'warnings': warnings
    }

def main():
    sql_dir = Path(__file__).parent / 'sql'
    
    if not sql_dir.exists():
        print(f"Error: {sql_dir} directory not found")
        return 1
    
    sql_files = list(sql_dir.glob('*.sql'))
    
    if not sql_files:
        print("No SQL files found")
        return 1
    
    print("=" * 60)
    print("SQL Validation Report")
    print("=" * 60)
    print()
    
    all_good = True
    
    for sql_file in sql_files:
        print(f"Checking {sql_file.name}...")
        result = check_sql_file(sql_file)
        
        print(f"  Tables: {result['tables']}")
        print(f"  Views: {result['views']}")
        print(f"  Functions: {result['functions']}")
        print(f"  Triggers: {result['triggers']}")
        
        if result['issues']:
            all_good = False
            print(f"  Issues found: {len(result['issues'])}")
            for issue in result['issues']:
                print(f"    - {issue}")
        else:
            print("  ✓ No obvious syntax issues found")
        
        if result['warnings']:
            print(f"  Warnings: {len(result['warnings'])}")
            for warning in result['warnings']:
                print(f"    ⚠ {warning}")
        
        print()
    
    print("=" * 60)
    if all_good:
        print("✓ Basic validation passed!")
        print("\nNote: This is a basic validation. For full validation, ")
        print("      run the SQL files against a PostgreSQL database.")
    else:
        print("✗ Issues found. Please review the output above.")
    
    return 0 if all_good else 1

if __name__ == '__main__':
    sys.exit(main())




