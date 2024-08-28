# CIC-filter

## VHDL implementacion of parametric CIC filter

Implementacion of CIC filter in VHDL for master's thesis.  
Filter uses generics to setup filter parameters.  

Used parameters are:  
- BIN_width: input data width
- BOUT_width: output data width
- M: number of cascading integrator and comb stages
- R: decimation factor
- N: differential delay for comb stages

