#!/usr/bin/env pwsh
# DP3 Phase 2 OpenLane Synthesis Script
# Simple version without special characters
# Date: 2026-04-23

param(
    [string]$LogPath = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3\Reports\phase2_synthesis.log"
)

$DesignDir = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3"
$ConfigFile = "$DesignDir\config_phase2.tcl"

function Write-Log {
    param([string]$Message, [string]$Type = "Info")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogPath -Value $LogMessage
}

function Run-Synthesis {
    Write-Log "================================================" "Info"
    Write-Log "DP3 Phase 2 OpenLane Synthesis" "Info"
    Write-Log "Clock Gating + Multi-Vt Optimization" "Info"
    Write-Log "================================================" "Info"
    Write-Log "" "Info"
    
    # Check prerequisites
    Write-Log "Checking prerequisites..." "Info"
    if (-not (Test-Path $ConfigFile)) {
        Write-Log "ERROR: config_phase2.tcl not found" "Error"
        return $false
    }
    Write-Log "OK: Config file found" "Info"
    
    # Build Docker command
    $DockerImage = "ghcr.io/the-openroad-project/openlane:latest"
    $VolumePath = $DesignDir
    
    Write-Log "" "Info"
    Write-Log "Running OpenLane synthesis..." "Info"
    Write-Log "Docker image: $DockerImage" "Info"
    Write-Log "Design directory: $VolumePath" "Info"
    Write-Log "" "Info"
    
    # Run Docker/OpenLane synthesis
    try {
        docker run --rm -it `
            -v "$VolumePath`:/openlane/designs/DP3" `
            $DockerImage `
            openlane /openlane/designs/DP3/config_phase2.tcl 2>&1 | Tee-Object -FilePath $LogPath -Append
        
        $SynthStatus = $LASTEXITCODE
        
        if ($SynthStatus -eq 0) {
            Write-Log "" "Info"
            Write-Log "================================================" "Info"
            Write-Log "SYNTHESIS COMPLETED SUCCESSFULLY" "Info"
            Write-Log "================================================" "Info"
            Write-Log "" "Info"
            Write-Log "Next steps:" "Info"
            Write-Log "1. Check power report in runs directory" "Info"
            Write-Log "2. Verify timing (WNS should be >= 0.0 ns)" "Info"
            Write-Log "3. Run functional regression tests" "Info"
            Write-Log "" "Info"
            Write-Log "Log saved to: $LogPath" "Info"
            return $true
        } else {
            Write-Log "" "Info"
            Write-Log "================================================" "Info"
            Write-Log "SYNTHESIS FAILED" "Error"
            Write-Log "Exit Code: $SynthStatus" "Error"
            Write-Log "================================================" "Error"
            Write-Log "Check log: $LogPath" "Error"
            return $false
        }
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Main execution
if (Test-Path $LogPath) {
    Clear-Content -Path $LogPath
}

$Result = Run-Synthesis
if ($Result) {
    exit 0
} else {
    exit 1
}
