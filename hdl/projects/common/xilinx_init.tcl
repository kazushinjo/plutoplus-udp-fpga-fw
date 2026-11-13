# Modified by Christos Nikolaou (SV1EIA) 2026.
# Christos Nikolaou can be reached by email at : sv1eia@gmail.com
# Setup IP Repositories
save_bd_design
close_bd_design system
set_property ip_repo_paths [list \
  "$::hdl_projects_dir/../dvb_fpga" \
  "$ad_hdl_dir/library" \
] [current_fileset]
update_ip_catalog -rebuild
open_bd_design $project_name.srcs/sources_1/bd/system/system.bd
source $ad_hdl_dir/projects/common/xilinx/adi_fir_filter_bd.tcl

# Default Global Ports
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr
create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 fixed_io

add_files -norecurse  $ad_hdl_dir/library/common/ad_bus_mux.v

#ps_7.tcl should be called after that
