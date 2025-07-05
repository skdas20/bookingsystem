#!/usr/bin/env bash

# Simple test script for the Appointment Booking API
# This script demonstrates all the API endpoints

BASE_URL="http://localhost:3000"

echo "🚀 Testing Appointment Booking System API"
echo "=========================================="

# Health check
echo "1. Health Check"
curl -s "$BASE_URL/health" | jq '.'
echo -e "\n"

# Register user
echo "2. Registering a new user..."
SIGNUP_RESPONSE=$(curl -s -X POST "$BASE_URL/api/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123"
  }')
echo "$SIGNUP_RESPONSE" | jq '.'
echo -e "\n"

# Login user
echo "3. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }')
echo "$LOGIN_RESPONSE" | jq '.'

# Extract token
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // empty')
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Failed to get authentication token"
  exit 1
fi

echo "✅ Got token: ${TOKEN:0:20}..."
echo -e "\n"

# Set availability
echo "4. Setting availability for Monday..."
AVAILABILITY_RESPONSE=$(curl -s -X POST "$BASE_URL/api/availability" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "dayOfWeek": 1,
    "startTime": "09:00",
    "endTime": "17:00",
    "intervalMin": 30,
    "timeZone": "America/New_York"
  }')
echo "$AVAILABILITY_RESPONSE" | jq '.'
echo -e "\n"

# Get availability
echo "5. Getting availability rules..."
curl -s -X GET "$BASE_URL/api/availability" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo -e "\n"

# Get slots (adjust dates for future)
TOMORROW=$(date -d "tomorrow" +%Y-%m-%d)
NEXT_WEEK=$(date -d "next week" +%Y-%m-%d)

echo "6. Getting available slots ($TOMORROW to $NEXT_WEEK)..."
SLOTS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/slots?from=$TOMORROW&to=$NEXT_WEEK" \
  -H "Authorization: Bearer $TOKEN")
echo "$SLOTS_RESPONSE" | jq '.'
echo -e "\n"

echo "🎉 API test completed!"
echo "Note: To test booking and cancellation, use a valid future slot from the slots response."
