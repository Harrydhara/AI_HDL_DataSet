# Mercer Team - Challenge [4]

##  Final Design Tape-out Challenge 

![design](https://github.com/[user]/MercerTeamAIHDL/blob/main/DP_1/img/design.png)

## Folder Layout

#### 'src' 
- '/rtl': Final RTL for reproduction
- '/tl': Top level harness & OpenLane config
- '/support': Support modules

#### 'openLane/reports' 
- '/cts': clock tree statistics report
- '/floorplan': core & die area report
- '/placement': global & detailed placement report
- '/routing': resizer design, timing, and global routing report
- '/signoff': Final timing, power, and clock report
- '/synthesis': pre-diff-post synthesis report

#### 'openLane/results' 
- '/final/def': design placed and routed format 
- '/final/gds': GDSII tape-out
- '/final/les': les layout
- '/floorplan': floorplan design placed and routed 
- '/placement': global + detailed placement
- '/routing': final routed design format
- '/synthesis': gate-level netlist 