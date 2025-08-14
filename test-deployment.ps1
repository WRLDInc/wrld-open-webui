# Open WebUI Deployment Health Check Script
# This script tests the deployment after it's live in Coolify

param(
    [Parameter(Mandatory=$false)]
    [string]$AppUrl = "http://localhost:3000",
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Open WebUI Deployment Health Check   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$results = @{
    TotalTests = 0
    Passed = 0
    Failed = 0
}

function Test-Endpoint {
    param(
        [string]$Url,
        [string]$TestName,
        [int]$ExpectedStatus = 200,
        [string]$ExpectedContent = $null
    )
    
    $results.TotalTests++
    Write-Host "Testing: $TestName" -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec 10
        
        if ($response.StatusCode -eq $ExpectedStatus) {
            if ($ExpectedContent -and -not ($response.Content -like "*$ExpectedContent*")) {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Host "  - Expected content not found: $ExpectedContent" -ForegroundColor Yellow
                $results.Failed++
            } else {
                Write-Host " [PASSED]" -ForegroundColor Green
                if ($Verbose) {
                    Write-Host "  - Status: $($response.StatusCode)" -ForegroundColor Gray
                    Write-Host "  - Content Length: $($response.Content.Length) bytes" -ForegroundColor Gray
                }
                $results.Passed++
            }
        } else {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Host "  - Expected status $ExpectedStatus, got $($response.StatusCode)" -ForegroundColor Yellow
            $results.Failed++
        }
    } catch {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host "  - Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $results.Failed++
    }
}

function Test-ContainerHealth {
    param([string]$ContainerName)
    
    $results.TotalTests++
    Write-Host "Checking container: $ContainerName" -NoNewline
    
    try {
        $containerInfo = docker inspect $ContainerName 2>$null | ConvertFrom-Json
        
        if ($containerInfo) {
            $status = $containerInfo[0].State.Status
            $health = $containerInfo[0].State.Health.Status
            
            if ($status -eq "running") {
                Write-Host " [RUNNING]" -ForegroundColor Green
                if ($health) {
                    Write-Host "  - Health: $health" -ForegroundColor $(if($health -eq "healthy"){"Green"}else{"Yellow"})
                }
                $results.Passed++
            } else {
                Write-Host " [NOT RUNNING]" -ForegroundColor Red
                Write-Host "  - Status: $status" -ForegroundColor Yellow
                $results.Failed++
            }
        } else {
            Write-Host " [NOT FOUND]" -ForegroundColor Red
            $results.Failed++
        }
    } catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Write-Host "  - Docker might not be accessible or container doesn't exist" -ForegroundColor Yellow
        $results.Failed++
    }
}

function Test-ResponseTime {
    param(
        [string]$Url,
        [string]$TestName,
        [int]$MaxMilliseconds = 3000
    )
    
    $results.TotalTests++
    Write-Host "Response time for: $TestName" -NoNewline
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec 10
        $stopwatch.Stop()
        
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        if ($responseTime -le $MaxMilliseconds) {
            Write-Host " [$responseTime ms]" -ForegroundColor Green
            $results.Passed++
        } else {
            Write-Host " [$responseTime ms]" -ForegroundColor Yellow
            Write-Host "  - Warning: Response time exceeds $MaxMilliseconds ms threshold" -ForegroundColor Yellow
            $results.Failed++
        }
    } catch {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host "  - Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $results.Failed++
    }
}

Write-Host "`n1. ENDPOINT HEALTH CHECKS" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow

# Test main application endpoints
Test-Endpoint -Url "$AppUrl/health" -TestName "Health Check Endpoint" -ExpectedStatus 200
Test-Endpoint -Url "$AppUrl/" -TestName "Main UI" -ExpectedStatus 200
Test-Endpoint -Url "$AppUrl/api/v1/auths" -TestName "Auth API" -ExpectedStatus 200
Test-Endpoint -Url "$AppUrl/docs" -TestName "API Documentation" -ExpectedStatus 200

Write-Host "`n2. CONTAINER STATUS" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow

# Check container status if Docker is available
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Test-ContainerHealth -ContainerName "open-webui"
    Test-ContainerHealth -ContainerName "ollama"
} else {
    Write-Host "Docker not available - skipping container checks" -ForegroundColor Yellow
}

Write-Host "`n3. PERFORMANCE CHECKS" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow

# Test response times
Test-ResponseTime -Url "$AppUrl/" -TestName "Main Page Load" -MaxMilliseconds 3000
Test-ResponseTime -Url "$AppUrl/health" -TestName "Health Check" -MaxMilliseconds 1000

Write-Host "`n4. OLLAMA INTEGRATION" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow

# Test Ollama connectivity through the proxy
Test-Endpoint -Url "$AppUrl/ollama/api/tags" -TestName "Ollama API (via proxy)" -ExpectedStatus 200

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           TEST SUMMARY                " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($results.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($results.Passed)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor $(if($results.Failed -gt 0){"Red"}else{"Green"})

$successRate = if ($results.TotalTests -gt 0) { 
    [math]::Round(($results.Passed / $results.TotalTests) * 100, 2) 
} else { 0 }

Write-Host "`nSuccess Rate: $successRate%" -ForegroundColor $(if($successRate -ge 80){"Green"}elseif($successRate -ge 60){"Yellow"}else{"Red"})

if ($results.Failed -gt 0) {
    Write-Host "`n⚠ Some tests failed. Please check the deployment logs." -ForegroundColor Yellow
    Write-Host "Run with -Verbose flag for more details." -ForegroundColor Gray
    exit 1
} else {
    Write-Host "`n✅ All tests passed! Deployment is healthy." -ForegroundColor Green
    exit 0
}
