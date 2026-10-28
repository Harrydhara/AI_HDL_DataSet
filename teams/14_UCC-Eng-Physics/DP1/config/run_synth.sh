#!/bin/bash

echo "Running baseline synthesis..."

yosys synth/synth.ys | tee reports/synth_report.txt

echo "Synthesis complete."
echo "Netlist: netlist/accel_netlist.v"
echo "Diagram: reports/accel.png"
