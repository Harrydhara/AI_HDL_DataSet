#!/usr/bin/env pwsh
# DP3 Phase 2 OpenLane Synthesis using Efabless image (has PDK pre-loaded)
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

Write-Log "=========================================" "Info"
Write-Log "DP3 Phase 2 Synthesis - Efabless OpenLane" "Info"
Write-Log "Clock Gating + Multi-Vt Optimization" "Info"
Write-Log "=========================================" "Info"
Write-Log "" "Info"
Write-Log "Using: efabless/openlane:latest (has PDK)" "Info"
Write-Log "" "Info"

# Run synthesis
docker run --rm -it `
    -v "$DesignDir`:/openlane/designs/DP3" `
    efabless/openlane:latest `
    bash -c "cd /openlane/designs/DP3 && flow.tcl -design . -tag phase2_synthesis 2>&1" 2>&1 | Tee-Object -FilePath $LogPath -Append

$SynthStatus = $LASTEXITCODE

Write-Log "" "Info"
Write-Log "=========================================" "Info"

if ($SynthStatus -eq 0) {
    Write-Log "SYNTHESIS COMPLETED SUCCESSFULLY" "Info"
    Write-Log "=========================================" "Info"
    Write-Log "" "Info"
    Write-Log "Results location: $DesignDir\runs\" "Info"
    Write-Log "Next: Extract power and timing reports" "Info"
    exit 0
} else {
    Write-Log "SYNTHESIS FAILED (Exit: $SynthStatus)" "Error"
    Write-Log "=========================================" "Error"
    Write-Log "Check: $LogPath" "Error"
    exit 1
}
