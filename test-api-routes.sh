#!/bin/bash

# API Route Testing Script
# This script tests all your API endpoints

API_URL="https://poros-data-service-ccpabd3jq-kofibaahnyarkos-projects.vercel.app"

echo "🧪 Testing API Routes..."
echo "API URL: $API_URL"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo "1️⃣  Testing Health Check (GET /health)..."
response=$(curl -s -w "\n%{http_code}" "$API_URL/health")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Health check passed${NC}"
    echo "   Response: $body"
else
    echo -e "${RED}❌ Health check failed (HTTP $http_code)${NC}"
    echo "   Response: $body"
fi
echo ""

# Test 2: Signup
echo "2️⃣  Testing Signup (POST /api/auth/signup)..."
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test'$(date +%s)'@example.com",
    "password": "password123",
    "university": "Test University",
    "major": "Computer Science",
    "graduationYear": 2024
  }')
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" == "201" ] || [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Signup successful${NC}"
    echo "   Response: $body"
    # Extract token if present
    token=$(echo "$body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$token" ]; then
        echo -e "${YELLOW}   Token extracted (will use for protected routes)${NC}"
        export TEST_TOKEN="$token"
    fi
elif [ "$http_code" == "400" ]; then
    echo -e "${YELLOW}⚠️  Signup validation error (might be duplicate email)${NC}"
    echo "   Response: $body"
else
    echo -e "${RED}❌ Signup failed (HTTP $http_code)${NC}"
    echo "   Response: $body"
fi
echo ""

# Test 3: Login
echo "3️⃣  Testing Login (POST /api/auth/login)..."
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }')
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Login successful${NC}"
    echo "   Response: $body"
    # Extract token
    token=$(echo "$body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$token" ]; then
        echo -e "${YELLOW}   Token extracted${NC}"
        export TEST_TOKEN="$token"
    fi
elif [ "$http_code" == "401" ]; then
    echo -e "${YELLOW}⚠️  Login failed (invalid credentials - expected if user doesn't exist)${NC}"
    echo "   Response: $body"
else
    echo -e "${RED}❌ Login failed (HTTP $http_code)${NC}"
    echo "   Response: $body"
fi
echo ""

# Test 4: Companies (may require auth)
echo "4️⃣  Testing Companies (GET /api/companies)..."
response=$(curl -s -w "\n%{http_code}" "$API_URL/api/companies")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" == "200" ]; then
    echo -e "${GREEN}✅ Companies endpoint works (no auth required)${NC}"
    echo "   Response: $(echo $body | head -c 100)..."
elif [ "$http_code" == "401" ]; then
    echo -e "${YELLOW}⚠️  Companies endpoint requires authentication${NC}"
    echo "   Response: $body"
    if [ ! -z "$TEST_TOKEN" ]; then
        echo -e "${YELLOW}   Retrying with token...${NC}"
        response=$(curl -s -w "\n%{http_code}" "$API_URL/api/companies" \
          -H "Authorization: Bearer $TEST_TOKEN")
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | head -n-1)
        if [ "$http_code" == "200" ]; then
            echo -e "${GREEN}   ✅ Works with token!${NC}"
        else
            echo -e "${RED}   ❌ Still failed (HTTP $http_code)${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Companies endpoint failed (HTTP $http_code)${NC}"
    echo "   Response: $body"
fi
echo ""

# Test 5: Applications (requires auth)
echo "5️⃣  Testing Applications (GET /api/applications)..."
if [ ! -z "$TEST_TOKEN" ]; then
    response=$(curl -s -w "\n%{http_code}" "$API_URL/api/applications" \
      -H "Authorization: Bearer $TEST_TOKEN")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ Applications endpoint works${NC}"
        echo "   Response: $(echo $body | head -c 100)..."
    else
        echo -e "${RED}❌ Applications endpoint failed (HTTP $http_code)${NC}"
        echo "   Response: $body"
    fi
else
    response=$(curl -s -w "\n%{http_code}" "$API_URL/api/applications")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    echo -e "${YELLOW}⚠️  Applications endpoint requires authentication${NC}"
    echo "   Response: $body"
fi
echo ""

# Test 6: Checklist (requires auth)
echo "6️⃣  Testing Checklist (GET /api/checklist)..."
if [ ! -z "$TEST_TOKEN" ]; then
    response=$(curl -s -w "\n%{http_code}" "$API_URL/api/checklist" \
      -H "Authorization: Bearer $TEST_TOKEN")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "200" ]; then
        echo -e "${GREEN}✅ Checklist endpoint works${NC}"
        echo "   Response: $(echo $body | head -c 100)..."
    else
        echo -e "${RED}❌ Checklist endpoint failed (HTTP $http_code)${NC}"
        echo "   Response: $body"
    fi
else
    response=$(curl -s -w "\n%{http_code}" "$API_URL/api/checklist")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    echo -e "${YELLOW}⚠️  Checklist endpoint requires authentication${NC}"
    echo "   Response: $body"
fi
echo ""

echo "🏁 Testing complete!"
echo ""
echo "💡 Tip: If you see 'No token provided' errors, that's expected for protected routes."
echo "   You need to sign up or log in first to get a token."

