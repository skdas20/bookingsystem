# Comprehensive API Endpoint Testing Script
# Tests all endpoints of the Appointment Booking System

Write-Host "🚀 STARTING COMPREHENSIVE API ENDPOINT TESTING" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$baseUrl = "http://localhost:3000"
$global:authToken = $null

# Helper function to make API calls
function Invoke-ApiCall {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [hashtable]$Headers = @{},
        [string]$Description
    )
    
    try {
        Write-Host "`n📡 Testing: $Description" -ForegroundColor Yellow
        
        $requestParams = @{
            Uri = "$baseUrl$Endpoint"
            Method = $Method
            Headers = $Headers
        }
        
        if ($Body) {
            $requestParams.Body = ($Body | ConvertTo-Json)
            $requestParams.ContentType = "application/json"
        }
        
        $response = Invoke-WebRequest @requestParams
        $responseData = $response.Content | ConvertFrom-Json
        
        Write-Host "✅ SUCCESS: Status $($response.StatusCode)" -ForegroundColor Green
        return @{ Success = $true; Data = $responseData; StatusCode = $response.StatusCode }
        
    } catch {
        $errorMessage = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            Write-Host "❌ FAILED: Status $statusCode - $errorMessage" -ForegroundColor Red
        } else {
            Write-Host "❌ FAILED: $errorMessage" -ForegroundColor Red
        }
        return @{ Success = $false; Error = $errorMessage }
    }
}

# 1. HEALTH CHECK
Write-Host "`n🏥 1. HEALTH CHECK ENDPOINT" -ForegroundColor Magenta
$healthResult = Invoke-ApiCall -Method "GET" -Endpoint "/health" -Description "Application Health Status"
if ($healthResult.Success) {
    Write-Host "   Status: $($healthResult.Data.status)" -ForegroundColor Green
    Write-Host "   Environment: $($healthResult.Data.environment)" -ForegroundColor Green
}

# 2. AUTHENTICATION ENDPOINTS
Write-Host "`n🔐 2. AUTHENTICATION ENDPOINTS" -ForegroundColor Magenta

# Signup
$signupData = @{
    name = "Test User $(Get-Random)"
    email = "testuser$(Get-Random)@example.com"
    password = "SecurePassword123!"
}
$signupResult = Invoke-ApiCall -Method "POST" -Endpoint "/api/signup" -Body $signupData -Description "User Registration"

if ($signupResult.Success) {
    Write-Host "   Created User: $($signupResult.Data.user.name) (ID: $($signupResult.Data.user.id))" -ForegroundColor Green
    
    # Login with the created user
    $loginData = @{
        email = $signupData.email
        password = $signupData.password
    }
    $loginResult = Invoke-ApiCall -Method "POST" -Endpoint "/api/login" -Body $loginData -Description "User Login"
    
    if ($loginResult.Success) {
        $global:authToken = $loginResult.Data.token
        Write-Host "   Logged in as: $($loginResult.Data.user.name)" -ForegroundColor Green
        Write-Host "   Token obtained: $($global:authToken.Substring(0,20))..." -ForegroundColor Green
    }
}

# Set up headers for authenticated requests
$authHeaders = @{
    "Authorization" = "Bearer $global:authToken"
}

# 3. AVAILABILITY MANAGEMENT ENDPOINTS
Write-Host "`n⏰ 3. AVAILABILITY MANAGEMENT ENDPOINTS" -ForegroundColor Magenta

if ($global:authToken) {
    # Create availability rule
    $availabilityData = @{
        dayOfWeek = 1  # Monday
        startTime = "09:00"
        endTime = "17:00"
        intervalMin = 30
        timeZone = "America/New_York"
    }
    $createAvailResult = Invoke-ApiCall -Method "POST" -Endpoint "/api/availability" -Body $availabilityData -Headers $authHeaders -Description "Create Availability Rule"
    
    if ($createAvailResult.Success) {
        $ruleId = $createAvailResult.Data.availability.id
        Write-Host "   Created Rule ID: $ruleId for Monday 09:00-17:00" -ForegroundColor Green
        
        # Get availability rules
        $getAvailResult = Invoke-ApiCall -Method "GET" -Endpoint "/api/availability" -Headers $authHeaders -Description "Get Availability Rules"
        
        if ($getAvailResult.Success) {
            Write-Host "   Total Rules: $($getAvailResult.Data.count)" -ForegroundColor Green
            foreach ($rule in $getAvailResult.Data.availability) {
                Write-Host "   Rule $($rule.id): Day $($rule.dayOfWeek), $($rule.startTime)-$($rule.endTime), $($rule.intervalMinutes)min intervals" -ForegroundColor Green
            }
        }
    }
}

# 4. SLOT MANAGEMENT ENDPOINTS
Write-Host "`n📅 4. SLOT MANAGEMENT ENDPOINTS" -ForegroundColor Magenta

if ($global:authToken) {
    $fromDate = (Get-Date).ToString("yyyy-MM-dd")
    $toDate = (Get-Date).AddDays(7).ToString("yyyy-MM-dd")
    
    $getSlotsResult = Invoke-ApiCall -Method "GET" -Endpoint "/api/slots?from=$fromDate`&to=$toDate" -Headers $authHeaders -Description "Get Available Slots"
    
    if ($getSlotsResult.Success) {
        Write-Host "   Available Slots: $($getSlotsResult.Data.count)" -ForegroundColor Green
        Write-Host "   Date Range: $fromDate to $toDate" -ForegroundColor Green
        Write-Host "   Host Timezone: $($getSlotsResult.Data.hostTimezone)" -ForegroundColor Green
        
        if ($getSlotsResult.Data.slots.Count -gt 0) {
            Write-Host "   First Available Slot: $($getSlotsResult.Data.slots[0].startLocal) - $($getSlotsResult.Data.slots[0].endLocal)" -ForegroundColor Green
            $global:testSlot = $getSlotsResult.Data.slots[0]
        }
    }
}

# 5. BOOKING MANAGEMENT ENDPOINTS
Write-Host "`n📝 5. BOOKING MANAGEMENT ENDPOINTS" -ForegroundColor Magenta

if ($global:authToken -and $global:testSlot) {
    # Create booking
    $bookingData = @{
        name = "John Doe"
        email = "john.doe@example.com"
        slotStart = $global:testSlot.start
        slotEnd = $global:testSlot.end
    }
    $createBookingResult = Invoke-ApiCall -Method "POST" -Endpoint "/api/book" -Body $bookingData -Headers $authHeaders -Description "Create Booking"
    
    if ($createBookingResult.Success) {
        $bookingId = $createBookingResult.Data.booking.bookingId
        $cancelCode = $createBookingResult.Data.booking.cancelCode
        Write-Host "   Booking Created: $bookingId" -ForegroundColor Green
        Write-Host "   Cancel Code: $cancelCode" -ForegroundColor Green
        
        # Get user's bookings
        $getBookingsResult = Invoke-ApiCall -Method "GET" -Endpoint "/api/bookings" -Headers $authHeaders -Description "Get User Bookings"
        
        if ($getBookingsResult.Success) {
            Write-Host "   Total Bookings: $($getBookingsResult.Data.count)" -ForegroundColor Green
            foreach ($booking in $getBookingsResult.Data.bookings) {
                Write-Host "   Booking: $($booking.bookingId) - $($booking.name) - $($booking.status)" -ForegroundColor Green
            }
        }
        
        # Test cancellation (only if booking is far enough in the future)
        $cancelData = @{
            bookingId = $bookingId
            cancelCode = $cancelCode
        }
        # Note: This might fail due to 12-hour cancellation policy
        $cancelResult = Invoke-ApiCall -Method "POST" -Endpoint "/api/cancel" -Body $cancelData -Description "Cancel Booking (might fail due to timing)"
        
        if ($cancelResult.Success) {
            Write-Host "   Booking Cancelled Successfully" -ForegroundColor Green
        } else {
            Write-Host "   Cancellation failed (likely due to 12-hour policy)" -ForegroundColor Yellow
        }
    }
}

# 6. ERROR HANDLING TESTS
Write-Host "`n❌ 6. ERROR HANDLING TESTS" -ForegroundColor Magenta

# Test invalid endpoint
$invalidResult = Invoke-ApiCall -Method "GET" -Endpoint "/api/invalid" -Description "Invalid Endpoint (should return 404)"

# Test unauthorized access
$unauthorizedResult = Invoke-ApiCall -Method "GET" -Endpoint "/api/availability" -Description "Unauthorized Access (should return 401)"

# Test invalid login
$invalidLoginData = @{
    email = "invalid@example.com"
    password = "wrongpassword"
}
$invalidLoginResult = Invoke-ApiCall -Method "POST" -Endpoint "/api/login" -Body $invalidLoginData -Description "Invalid Login (should return 401)"

Write-Host "`n🎉 COMPREHENSIVE API TESTING COMPLETED!" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
