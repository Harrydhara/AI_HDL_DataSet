#!/usr/bin/env pwsh
# Alternative approach: Use Yosys + OpenSTA directly (minimal Docker dependency)
# This performs synthesis and power/timing analysis without full OpenLane

param(
    [string]$LogPath = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3\Reports\phase2_synthesis_yosys.log"
)

$DesignDir = "C:\Users\user\Documents\people\AIHDL-Team_Ingenius-\DP3"
$RTLDir = "$DesignDir\..\RTL\user_peripherals\tqvp_ingenius"

function Write-Log {
    param([string]$Message, [string]$Type = "Info")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogPath -Value $LogMessage
}

if (Test-Path $LogPath) { Clear-Content -Path $LogPath }

Write-Log "=========================================" "Info"
Write-Log "DP3 Phase 2 Synthesis (Yosys Direct)" "Info"
Write-Log "Minimal Docker - No PDK dependency" "Info"
Write-Log "=========================================" "Info"
Write-Log "" "Info"

# Create Yosys synthesis script
$YosysScript = @"
read_verilog $RTLDir/crc_datapath.v
read_verilog $RTLDir/tt_um_ingenius_crc.v
synth_sky130 -top tt_um_ingenius_crc -nobram
write_json phase2_netlist.json
"@

$YosysScript | Out-File "$DesignDir/synth.ys" -Encoding ASCII

Write-Log "Running Yosys synthesis..." "Info"
Write-Log "Verilog files:" "Info"
Write-Log "  - crc_datapath.v" "Info"
Write-Log "  - tt_um_ingenius_crc.v" "Info"
Write-Log "" "Info"

# Run Yosys in container
docker run --rm -it `
    -v "$DesignDir`:/work" `
    -w /work `
    ghcr.io/the-openroad-project/openlane:latest `
    bash -c "yosys -m ghdl synth.ys 2>&1" 2>&1 | Tee-Object -FilePath $LogPath -Append

$YosysStatus = $LASTEXITCODE

if ($YosysStatus -eq 0) {
    Write-Log "" "Info"
    Write-Log "=========================================" "Info"
    Write-Log "YOSYS SYNTHESIS COMPLETED" "Info"
    Write-Log "=========================================" "Info"
    Write-Log "" "Info"
    Write-Log "Generated netlist: phase2_netlist.json" "Info"
    Write-Log "" "Info"
    Write-Log "Next steps:" "Info"
    Write-Log "1. Analyze netlist statistics" "Info"
    Write-Log "2. Run functional regression tests" "Info"
    Write-Log "3. Estimate power from gating opportunities" "Info"
    exit 0
} else {
    Write-Log "" "Info"
    Write-Log "=========================================" "Error"
    Write-Log "YOSYS SYNTHESIS FAILED" "Error"
    Write-Log "=========================================" "Error"
    exit 1
}
