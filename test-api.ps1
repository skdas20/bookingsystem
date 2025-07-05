# PowerShell test script for the Appointment Booking API
# This script demonstrates all the API endpoints

$BaseUrl = "http://localhost:3000"

Write-Host "🚀 Testing Appointment Booking System API" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Health check
Write-Host "1. Health Check" -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get
    $healthResponse | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
}
Write-Host ""

# Register user
Write-Host "2. Registering a new user..." -ForegroundColor Yellow
$signupBody = @{
    name = "Test User"
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

try {
    $signupResponse = Invoke-RestMethod -Uri "$BaseUrl/api/signup" -Method Post -ContentType "application/json" -Body $signupBody
    $signupResponse | ConvertTo-Json -Depth 10
} catch {
    Write-Host "⚠️ Signup failed (user might already exist): $_" -ForegroundColor Yellow
}
Write-Host ""

# Login user
Write-Host "3. Logging in..." -ForegroundColor Yellow
$loginBody = @{
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$BaseUrl/api/login" -Method Post -ContentType "application/json" -Body $loginBody
    $loginResponse | ConvertTo-Json -Depth 10
    
    $token = $loginResponse.token
    if ($token) {
        Write-Host "✅ Got token: $($token.Substring(0, [Math]::Min(20, $token.Length)))..." -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to get authentication token" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Login failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Set availability
Write-Host "4. Setting availability for Monday..." -ForegroundColor Yellow
$availabilityBody = @{
    dayOfWeek = 1
    startTime = "09:00"
    endTime = "17:00"
    intervalMin = 30
    timeZone = "America/New_York"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

try {
    $availabilityResponse = Invoke-RestMethod -Uri "$BaseUrl/api/availability" -Method Post -Headers $headers -Body $availabilityBody
    $availabilityResponse | ConvertTo-Json -Depth 10
} catch {
    Write-Host "⚠️ Setting availability failed (might already exist): $_" -ForegroundColor Yellow
}
Write-Host ""

# Get availability
Write-Host "5. Getting availability rules..." -ForegroundColor Yellow
try {
    $getAvailabilityResponse = Invoke-RestMethod -Uri "$BaseUrl/api/availability" -Method Get -Headers @{"Authorization" = "Bearer $token"}
    $getAvailabilityResponse | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Getting availability failed: $_" -ForegroundColor Red
}
Write-Host ""

# Get slots (adjust dates for future)
$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
$nextWeek = (Get-Date).AddDays(7).ToString("yyyy-MM-dd")

Write-Host "6. Getting available slots ($tomorrow to $nextWeek)..." -ForegroundColor Yellow
try {
    $slotsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/slots?from=$tomorrow&to=$nextWeek" -Method Get -Headers @{"Authorization" = "Bearer $token"}
    $slotsResponse | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Getting slots failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "🎉 API test completed!" -ForegroundColor Green
Write-Host "Note: To test booking and cancellation, use a valid future slot from the slots response." -ForegroundColor Cyan
