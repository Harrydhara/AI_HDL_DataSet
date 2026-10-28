#!/usr/bin/env pwsh
# DP3 Phase 2 OpenLane Synthesis with PDK Setup
# Fixes: Downloads PDK with Volare, then runs synthesis
# Date: 2026-04-23

param(
    [string]$LogPath = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3\Reports\phase2_synthesis.log"
)

$DesignDir = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3"

function Write-Log {
    param([string]$Message, [string]$Type = "Info")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogPath -Value $LogMessage
}

# Clear log
if (Test-Path $LogPath) { Clear-Content -Path $LogPath }

Write-Log "================================================" "Info"
Write-Log "DP3 Phase 2 OpenLane Synthesis" "Info"
Write-Log "Clock Gating + Multi-Vt Optimization" "Info"
Write-Log "================================================" "Info"
Write-Log "" "Info"

# Step 1: Fetch PDK
Write-Log "Step 1: Fetching sky130 PDK..." "Info"
Write-Log "This may take 2-5 minutes on first run" "Info"

docker run --rm -it ghcr.io/the-openroad-project/openlane:latest bash -c "volare fetch sky130" 2>&1 | Tee-Object -FilePath $LogPath -Append

if ($LASTEXITCODE -ne 0) {
    Write-Log "WARNING: Volare fetch had issues, but continuing anyway" "Warning"
}

Write-Log "" "Info"
Write-Log "Step 2: Running OpenLane synthesis..." "Info"
Write-Log "Expected duration: 10-20 minutes" "Info"
Write-Log "" "Info"

# Step 2: Run synthesis
docker run --rm -it `
    -v "$DesignDir`:/openlane/designs/DP3" `
    ghcr.io/the-openroad-project/openlane:latest `
    bash -c "cd /openlane && flow.tcl -design /openlane/designs/DP3 -tag phase2_synthesis 2>&1" 2>&1 | Tee-Object -FilePath $LogPath -Append

$SynthStatus = $LASTEXITCODE

Write-Log "" "Info"
Write-Log "================================================" "Info"

if ($SynthStatus -eq 0) {
    Write-Log "SYNTHESIS COMPLETED SUCCESSFULLY" "Info"
    Write-Log "================================================" "Info"
    Write-Log "" "Info"
    Write-Log "Next steps:" "Info"
    Write-Log "1. Check results in: $DesignDir\runs\" "Info"
    Write-Log "2. Extract power report and timing summary" "Info"
    Write-Log "3. Run functional regression tests" "Info"
    Write-Log "" "Info"
    exit 0
} else {
    Write-Log "SYNTHESIS FAILED (Exit code: $SynthStatus)" "Error"
    Write-Log "================================================" "Error"
    Write-Log "Check log: $LogPath" "Error"
    Write-Log "" "Error"
    exit 1
}
