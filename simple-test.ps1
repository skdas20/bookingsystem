# Simple API Testing Script
Write-Host "🚀 TESTING ALL API ENDPOINTS" -ForegroundColor Cyan

$baseUrl = "http://localhost:3000"

# 1. Health Check
Write-Host "`n1. Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "$baseUrl/health"
    Write-Host "✅ Health Check: $($health.StatusCode)" -ForegroundColor Green
    $healthData = $health.Content | ConvertFrom-Json
    Write-Host "   Status: $($healthData.status), Environment: $($healthData.environment)"
} catch {
    Write-Host "❌ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. User Signup
Write-Host "`n2. Testing User Signup..." -ForegroundColor Yellow
$signupBody = @{
    name = "Test User $(Get-Random)"
    email = "testuser$(Get-Random)@example.com" 
    password = "SecurePass123!"
} | ConvertTo-Json

try {
    $signup = Invoke-WebRequest -Uri "$baseUrl/api/signup" -Method POST -Body $signupBody -ContentType "application/json"
    Write-Host "✅ Signup: $($signup.StatusCode)" -ForegroundColor Green
    $signupData = $signup.Content | ConvertFrom-Json
    Write-Host "   User created: $($signupData.user.name) (ID: $($signupData.user.id))"
    $testEmail = ($signupBody | ConvertFrom-Json).email
    $testPassword = ($signupBody | ConvertFrom-Json).password
} catch {
    Write-Host "❌ Signup Failed: $($_.Exception.Message)" -ForegroundColor Red
    # Use existing user for testing
    $testEmail = "newuser@example.com"
    $testPassword = "Password123!"
}

# 3. User Login
Write-Host "`n3. Testing User Login..." -ForegroundColor Yellow
$loginBody = @{
    email = $testEmail
    password = $testPassword
} | ConvertTo-Json

try {
    $login = Invoke-WebRequest -Uri "$baseUrl/api/login" -Method POST -Body $loginBody -ContentType "application/json"
    Write-Host "✅ Login: $($login.StatusCode)" -ForegroundColor Green
    $loginData = $login.Content | ConvertFrom-Json
    $authToken = $loginData.token
    Write-Host "   Logged in as: $($loginData.user.name)"
} catch {
    Write-Host "❌ Login Failed: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Setup auth headers
$headers = @{
    "Authorization" = "Bearer $authToken"
    "Content-Type" = "application/json"
}

# 4. Create Availability Rule
Write-Host "`n4. Testing Create Availability..." -ForegroundColor Yellow
$availBody = @{
    dayOfWeek = 1
    startTime = "09:00"
    endTime = "17:00"
    intervalMin = 30
    timeZone = "America/New_York"
} | ConvertTo-Json

try {
    $availability = Invoke-WebRequest -Uri "$baseUrl/api/availability" -Method POST -Body $availBody -Headers $headers
    Write-Host "✅ Create Availability: $($availability.StatusCode)" -ForegroundColor Green
    $availData = $availability.Content | ConvertFrom-Json
    Write-Host "   Created rule ID: $($availData.availability.id) for Monday"
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "⚠️  Availability rule already exists (expected)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Create Availability Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 5. Get Availability Rules
Write-Host "`n5. Testing Get Availability..." -ForegroundColor Yellow
try {
    $getAvail = Invoke-WebRequest -Uri "$baseUrl/api/availability" -Method GET -Headers $headers
    Write-Host "✅ Get Availability: $($getAvail.StatusCode)" -ForegroundColor Green
    $availListData = $getAvail.Content | ConvertFrom-Json
    Write-Host "   Found $($availListData.count) availability rules"
} catch {
    Write-Host "❌ Get Availability Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Get Available Slots
Write-Host "`n6. Testing Get Slots..." -ForegroundColor Yellow
$fromDate = (Get-Date).ToString("yyyy-MM-dd")
$toDate = (Get-Date).AddDays(7).ToString("yyyy-MM-dd")
$slotsUri = "$baseUrl/api/slots?from=$fromDate" + "&to=$toDate"

try {
    $slots = Invoke-WebRequest -Uri $slotsUri -Method GET -Headers $headers
    Write-Host "✅ Get Slots: $($slots.StatusCode)" -ForegroundColor Green
    $slotsData = $slots.Content | ConvertFrom-Json
    Write-Host "   Found $($slotsData.count) available slots"
    if ($slotsData.slots.Count -gt 0) {
        $testSlot = $slotsData.slots[0]
        Write-Host "   First slot: $($testSlot.startLocal) - $($testSlot.endLocal)"
    }
} catch {
    Write-Host "❌ Get Slots Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. Create Booking (if we have slots)
if ($testSlot) {
    Write-Host "`n7. Testing Create Booking..." -ForegroundColor Yellow
    $bookingBody = @{
        name = "John Doe"
        email = "john.doe@example.com"
        slotStart = $testSlot.start
        slotEnd = $testSlot.end
    } | ConvertTo-Json

    try {
        $booking = Invoke-WebRequest -Uri "$baseUrl/api/book" -Method POST -Body $bookingBody -Headers $headers
        Write-Host "✅ Create Booking: $($booking.StatusCode)" -ForegroundColor Green
        $bookingData = $booking.Content | ConvertFrom-Json
        Write-Host "   Booking ID: $($bookingData.booking.bookingId)"
        $bookingId = $bookingData.booking.bookingId
        $cancelCode = $bookingData.booking.cancelCode
    } catch {
        Write-Host "❌ Create Booking Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 8. Get User Bookings
Write-Host "`n8. Testing Get Bookings..." -ForegroundColor Yellow
try {
    $bookings = Invoke-WebRequest -Uri "$baseUrl/api/bookings" -Method GET -Headers $headers
    Write-Host "✅ Get Bookings: $($bookings.StatusCode)" -ForegroundColor Green
    $bookingsData = $bookings.Content | ConvertFrom-Json
    Write-Host "   Found $($bookingsData.count) bookings"
} catch {
    Write-Host "❌ Get Bookings Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. Test Error Handling
Write-Host "`n9. Testing Error Handling..." -ForegroundColor Yellow

# Test 404
try {
    $notFound = Invoke-WebRequest -Uri "$baseUrl/api/nonexistent" -Method GET
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "✅ 404 Error Handling: Working correctly" -ForegroundColor Green
    }
}

# Test 401 Unauthorized
try {
    $unauthorized = Invoke-WebRequest -Uri "$baseUrl/api/availability" -Method GET
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ 401 Auth Error Handling: Working correctly" -ForegroundColor Green
    }
}

Write-Host "`n🎉 API Testing Complete!" -ForegroundColor Cyan
