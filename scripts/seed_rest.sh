#!/bin/bash
# Firestore REST API seed script
# Uses Firebase REST API without requiring service account

PROJECT_ID="giadinh-ca079"
API_KEY="AIzaSyDGgE1EgumkGx2LBoiOnDDTzix8tCX4GGI"

FAMILY_ID="family_main"
BA_UID="seed_ba_admin"
ME_UID="seed_me_manager"
CON_UID="seed_con_child"

BASE_URL="https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents"

echo "🔄 Creating seed users..."

# Create Ba user
curl -X PATCH \
  "$BASE_URL/users/$BA_UID?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "email": {"stringValue": "ba@family.finance"},
      "displayName": {"stringValue": "Ba"},
      "role": {"stringValue": "fatherAdmin"},
      "familyId": {"stringValue": "'$FAMILY_ID'"}
    }
  }' 2>&1 | grep -q "error" && echo "❌ Failed to create Ba" || echo "✅ Ba created"

# Create Mẹ user
curl -X PATCH \
  "$BASE_URL/users/$ME_UID?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "email": {"stringValue": "me@family.finance"},
      "displayName": {"stringValue": "Mẹ"},
      "role": {"stringValue": "motherManager"},
      "familyId": {"stringValue": "'$FAMILY_ID'"}
    }
  }' 2>&1 | grep -q "error" && echo "❌ Failed to create Mẹ" || echo "✅ Mẹ created"

# Create Con user
curl -X PATCH \
  "$BASE_URL/users/$CON_UID?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "email": {"stringValue": "con@family.finance"},
      "displayName": {"stringValue": "Con"},
      "role": {"stringValue": "childLimited"},
      "familyId": {"stringValue": "'$FAMILY_ID'"}
    }
  }' 2>&1 | grep -q "error" && echo "❌ Failed to create Con" || echo "✅ Con created"

echo "✅ Seed complete!"
