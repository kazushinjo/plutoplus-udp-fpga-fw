# DMA memory path: the ADC and DAC DMAs go to the PS7 DDR through HP2.
# HP1 is not used and is turned off so its clock pin is not left
# unconnected. The ADC FIFO keeps its default connection to the ADC pack.

ad_ip_parameter sys_ps7 CONFIG.PCW_USE_S_AXI_HP1 {0}

ad_mem_hp2_interconnect sys_cpu_clk sys_ps7/S_AXI_HP2
ad_mem_hp2_interconnect sys_cpu_clk axi_ad9361_adc_dma/m_dest_axi
ad_mem_hp2_interconnect sys_cpu_clk axi_ad9361_dac_dma/m_src_axi
