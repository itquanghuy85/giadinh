# Firestore REST API Seed Script

$PROJECT_ID = "giadinh-ca079"
$API_KEY = "AIzaSyDGgE1EgumkGx2LBoiOnDDTzix8tCX4GGI"
$FAMILY_ID = "family_main"
$BASE_URL = "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents"

function Create-User {
    param([string]$uid, [string]$email, [string]$displayName, [string]$role)
    
    $url = "$BASE_URL/users/$uid`?key=$API_KEY"
    $body = @{
        fields = @{
            email = @{ stringValue = $email }
            displayName = @{ stringValue = $displayName }
            role = @{ stringValue = $role }
            familyId = @{ stringValue = $FAMILY_ID }
        }
    } | ConvertTo-Json -Depth 5
    
    try {
        Write-Host "Creating user: $displayName ($email)..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Method PATCH -Headers @{ "Content-Type" = "application/json" } -Body $body -ErrorAction Stop
        Write-Host "OK: $displayName" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "ERROR: $displayName - $_" -ForegroundColor Red
        return $false
    }
}

Write-Host "Starting seed data..." -ForegroundColor Yellow
Create-User "seed_ba_admin" "ba@family.finance" "Ba" "fatherAdmin"
Create-User "seed_me_manager" "me@family.finance" "Me" "motherManager"
Create-User "seed_con_child" "con@family.finance" "Con" "childLimited"
Write-Host "Seed complete!" -ForegroundColor Green
