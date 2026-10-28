#!/usr/bin/env pwsh
# DP3 Phase 2 OpenLane Synthesis Script
# Purpose: Run clock gating + Multi-Vt optimization synthesis
# Date: 2026-04-23

param(
    [string]$LogPath = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3\Reports\phase2_synthesis.log",
    [switch]$NoDocker,
    [string]$DockerImage = "ghcr.io/the-openroad-project/openlane:latest"
)

# Configuration
$DesignDir = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3"
$ConfigFile = "$DesignDir\config_phase2.tcl"
$HVtCandidates = "$DesignDir\hvt_candidates_phase2.txt"

# Colors for output
$Colors = @{
    Success = 'Green'
    Error = 'Red'
    Warning = 'Yellow'
    Info = 'Cyan'
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"
    Write-Host $LogMessage -ForegroundColor $Colors[$Type]
    Add-Content -Path $LogPath -Value $LogMessage
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." "Info"
    
    # Check config file exists
    if (-not (Test-Path $ConfigFile)) {
        Write-Log "ERROR: config_phase2.tcl not found at $ConfigFile" "Error"
        return $false
    }
    Write-Log "✓ Config file found" "Success"
    
    # Check HVt candidates file
    if (-not (Test-Path $HVtCandidates)) {
        Write-Log "ERROR: hvt_candidates_phase2.txt not found at $HVtCandidates" "Error"
        return $false
    }
    Write-Log "✓ HVt candidates file found" "Success"
    
    # Check RTL files
    $RTLFiles = @(
        "$DesignDir\RTL\crc_datapath.v",
        "$DesignDir\RTL\crc_datapath_tb.v"
    )
    
    foreach ($file in $RTLFiles) {
        if (-not (Test-Path $file)) {
            Write-Log "WARNING: RTL file not found: $file" "Warning"
        } else {
            Write-Log "✓ RTL file found: $(Split-Path -Leaf $file)" "Success"
        }
    }
    
    # Check Docker
    if (-not $NoDocker) {
        try {
            $DockerVersion = & docker --version 2>&1
            Write-Log "✓ Docker found: $DockerVersion" "Success"
        } catch {
            Write-Log "ERROR: Docker not found. Install Docker or use -NoDocker flag" "Error"
            return $false
        }
    }
    
    return $true
}

function Start-Synthesis {
    Write-Log "Starting DP3 Phase 2 synthesis..." "Info"
    Write-Log "Configuration: $ConfigFile" "Info"
    Write-Log "HVt Candidates: $(Get-Item $HVtCandidates | Select-Object -ExpandProperty Length) bytes" "Info"
    
    # Create results directory
    $ResultsDir = "$DesignDir\Reports\phase2_results"
    if (-not (Test-Path $ResultsDir)) {
        New-Item -ItemType Directory -Path $ResultsDir | Out-Null
        Write-Log "Created results directory: $ResultsDir" "Info"
    }
    
    # Build Docker command
    $DockerCmd = @(
        "docker", "run", "--rm", "-it",
        "-v", "$($DesignDir):/openlane/designs/DP3",
        $DockerImage,
        "openlane", "designs/DP3/config_phase2.tcl"
    )
    
    Write-Log "Docker command: $($DockerCmd -join ' ')" "Info"
    Write-Log "═══════════════════════════════════════════════════" "Info"
    Write-Log "Starting OpenLane synthesis..." "Info"
    Write-Log "═══════════════════════════════════════════════════" "Info"
    
    # Run synthesis
    $StartTime = Get-Date
    try {
        & $DockerCmd[0] $DockerCmd[1..($DockerCmd.Length-1)] | Tee-Object -FilePath $LogPath -Append
        
        $ExitCode = $LASTEXITCODE
        if ($ExitCode -eq 0) {
            Write-Log "═══════════════════════════════════════════════════" "Info"
            Write-Log "✓ Synthesis completed successfully!" "Success"
        } else {
            Write-Log "✗ Synthesis failed with exit code: $ExitCode" "Error"
            return $false
        }
    } catch {
        Write-Log "ERROR: Synthesis execution failed: $_" "Error"
        return $false
    }
    
    $EndTime = Get-Date
    $Duration = ($EndTime - $StartTime).TotalMinutes
    Write-Log "Synthesis duration: $([math]::Round($Duration, 2)) minutes" "Info"
    
    return $true
}

function Extract-Results {
    Write-Log "Extracting synthesis results..." "Info"
    
    # Expected output locations in Docker container
    $DockerRunDir = "/openlane/designs/DP3/runs"
    
    Write-Log "Results will be available in: $DockerRunDir" "Info"
    Write-Log "Check for:" "Info"
    Write-Log "  - reports/31-rcx_sta.power.rpt (Power report)" "Info"
    Write-Log "  - reports/31-rcx_sta.summary.rpt (Timing summary)" "Info"
    Write-Log "  - results/final.v (Gate-level netlist)" "Info"
    Write-Log "  - results/final.def (Placement definition)" "Info"
    
    # Check if synthesis created any output
    $LatestRun = Get-ChildItem -Path "$DesignDir\runs" -Directory -ErrorAction SilentlyContinue | 
                 Sort-Object LastWriteTime -Descending | 
                 Select-Object -First 1
    
    if ($LatestRun) {
        Write-Log "Latest synthesis run: $($LatestRun.Name)" "Success"
        
        # Extract power report
        $PowerReport = "$($LatestRun.FullName)\reports\31-rcx_sta.power.rpt"
        if (Test-Path $PowerReport) {
            Write-Log "Power report found:" "Success"
            $PowerData = Get-Content $PowerReport | Select-String "^Total"
            if ($PowerData) {
                Write-Log "$PowerData" "Info"
            }
        }
        
        # Extract timing summary
        $TimingSummary = "$($LatestRun.FullName)\reports\31-rcx_sta.summary.rpt"
        if (Test-Path $TimingSummary) {
            Write-Log "Timing summary found:" "Success"
            Get-Content $TimingSummary | Select-String "slack|wns|tns" | ForEach-Object {
                Write-Log "$_" "Info"
            }
        }
    } else {
        Write-Log "Note: Check Docker OpenLane container for detailed output" "Warning"
    }
}

function Show-Summary {
    Write-Log '===================================================' "Info"
    Write-Log 'PHASE 2 SYNTHESIS SUMMARY' "Info"
    Write-Log '===================================================' "Info"
    Write-Log 'Configuration: Clock Gating + Multi-Vt Optimization' "Info"
    Write-Log 'Target Power: 6.0-6.3 mW - 8-10 percent reduction' "Info"
    Write-Log 'Target Timing: WNS greater than or equal to 0.0 ns' "Info"
    Write-Log '===================================================' "Info"
    Write-Log '' "Info"
    Write-Log 'Next Steps:' "Info"
    Write-Log '1. Check power report in results directory' "Info"
    Write-Log '2. Verify timing closure' "Info"
    Write-Log '3. Run functional tests with new netlist' "Info"
    Write-Log '4. Compare power: 7.81 mW DP2 vs ? mW DP3-A' "Info"
    Write-Log '' "Info"
    Write-Log "Log file: $LogPath" "Info"
}

# Main execution
function Main {
    # Clear/create log file
    if (Test-Path $LogPath) {
        Clear-Content -Path $LogPath
    } else {
        New-Item -ItemType File -Path $LogPath -Force | Out-Null
    }
    
    Write-Log "=====================================================" "Info"
    Write-Log "   DP3 Phase 2 - OpenLane Synthesis Script         " "Info"
    Write-Log "   Clock Gating + Multi-Vt Optimization            " "Info"
    Write-Log "   Date: 2026-04-23                                " "Info"
    Write-Log "=====================================================" "Info"
    Write-Log "" "Info"
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Log "Prerequisites check failed. Aborting." "Error"
        exit 1
    }
    
    Write-Log "" "Info"
    
    # Run synthesis
    if (Test-Synthesis) {
        Write-Log "" "Info"
        Extract-Results
        Write-Log "" "Info"
        Show-Summary
        exit 0
    } else {
        Write-Log "Synthesis failed. Check log for details." "Error"
        Show-Summary
        exit 1
    }
}

# Helper function with correct name
function Test-Synthesis {
    return (Start-Synthesis)
}

# Run main
Main
