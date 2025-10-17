#!/bin/bash

# srsRAN 4G Setup Script for Ubuntu 24.04
# Based on SDR Documentation

set -e

echo "=== srsRAN 4G Setup Script ==="

# Install dependencies for srsRAN 4G
echo "Installing srsRAN 4G dependencies..."
sudo apt-get install cmake make gcc-11 g++-11 pkg-config libfftw3-dev \
    libmbedtls-dev libboost-program-options-dev libboost-system-dev libconfig++-dev libsctp-dev git -y

# Set GCC version
export CC=$(which gcc-11)
export CXX=$(which g++-11)

# Define custom configuration function
configure_srsran_4g() {
    echo "Creating comprehensive eNodeB configuration aligned with project .conf files..."

    # Create comprehensive enb.conf aligned with project enb.conf
    sudo tee /etc/srsran/enb.conf > /dev/null <<EOF
#####################################################################
#                   srsENB configuration file
#####################################################################

#####################################################################
# eNB configuration
#
# enb_id:               20-bit eNB identifier.
# mcc:                  Mobile Country Code
# mnc:                  Mobile Network Code
# mme_addr:             IP address of MME for S1 connnection
# gtp_bind_addr:        Local IP address to bind for GTP connection
# gtp_advertise_addr:   IP address of eNB to advertise for DL GTP-U Traffic
# s1c_bind_addr:        Local IP address to bind for S1AP connection
# s1c_bind_port:        Source port for S1AP connection (0 means any)
# n_prb:                Number of Physical Resource Blocks (6,15,25,50,75,100)
# tm:                   Transmission mode 1-4 (TM1 default)
# nof_ports:            Number of Tx ports (1 port default, set to 2 for TM2/3/4)
#
#####################################################################
[enb]
enb_id = 0x19B
mcc = 001
mnc = 01
mme_addr = 127.0.1.2
gtp_bind_addr = 127.0.1.1
s1c_bind_addr = 127.0.1.1
s1c_bind_port = 0
n_prb = 50
#tm = 4
#nof_ports = 2

#####################################################################
# eNB configuration files
#
# sib_config:  SIB1, SIB2 and SIB3 configuration file
# note: When enabling MBMS, use the sib.conf.mbsfn configuration file which includes SIB13
# rr_config:   Radio Resources configuration file
# rb_config:   SRB/DRB configuration file
#####################################################################
[enb_files]
sib_config = sib.conf
rr_config  = rr.conf
rb_config = rb.conf

#####################################################################
# RF configuration
#
# dl_earfcn: EARFCN code for DL (only valid if a single cell is configured in rr.conf)
# tx_gain: Transmit gain (dB).
# rx_gain: Optional receive gain (dB). If disabled, AGC if enabled
#
# Optional parameters:
# dl_freq:            Override DL frequency corresponding to dl_earfcn
# ul_freq:            Override UL frequency corresponding to dl_earfcn
# device_name:        Device driver family
#                     Supported options: "auto" (uses first driver found), "UHD", "bladeRF", "soapy", "zmq" or "Sidekiq"
# device_args:        Arguments for the device driver. Options are "auto" or any string.
#                     Default for UHD: "recv_frame_size=9232,send_frame_size=9232"
#                     Default for bladeRF: ""
# time_adv_nsamples:  Transmission time advance (in number of samples) to compensate for RF delay
#                     from antenna to timestamp insertion.
#                     Default "auto". B210 USRP: 100 samples, bladeRF: 27
#####################################################################
[rf]
#dl_earfcn = 3350
tx_gain = 80
rx_gain = 40

device_name = UHD

# For best performance in 2x2 MIMO and >= 15 MHz use the following device_args settings:
#     USRP B210: num_recv_frames=64,num_send_frames=64
#     And for 75 PRBs, also append ",master_clock_rate=15.36e6" to the device args

# For best performance when BW<5 MHz (25 PRB), use the following device_args settings:
#     USRP B210: send_frame_size=512,recv_frame_size=512

device_args = type=b200,num_recv_frames=64,num_send_frames=64
#time_adv_nsamples = auto

# Example for ZMQ-based operation with TCP transport for I/Q samples
#device_name = zmq
#device_args = fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=23.04e6

#####################################################################
# Packet capture configuration
#####################################################################
[pcap]
#enable = false
#filename = /tmp/enb_mac.pcap
#nr_filename = /tmp/enb_mac_nr.pcap
#s1ap_enable = false
#s1ap_filename = /tmp/enb_s1ap.pcap

#mac_net_enable = false
#bind_ip = 0.0.0.0
#bind_port = 5687
#client_ip = 127.0.0.1
#client_port = 5847

#####################################################################
# Log configuration
#####################################################################
[log]
all_level = warning
all_hex_limit = 32
filename = /tmp/enb.log
file_max_size = -1

[gui]
enable = false

#####################################################################
# Scheduler configuration options
#####################################################################
[scheduler]
#policy     = time_pf
#policy_args = 2
#min_aggr_level   = 0
#max_aggr_level   = 3
#adaptive_aggr_level = false
#pdsch_mcs        = -1
#pdsch_max_mcs    = -1
#pusch_mcs        = -1
#pusch_max_mcs    = 16
#min_nof_ctrl_symbols = 1
#max_nof_ctrl_symbols = 3
#pucch_multiplex_enable = false
#pucch_harq_max_rb = 0
#target_bler = 0.05
#max_delta_dl_cqi = 5
#max_delta_ul_snr = 5
#adaptive_dl_mcs_step_size = 0.001
#adaptive_ul_mcs_step_size = 0.001
#min_tpc_tti_interval = 1
#ul_snr_avg_alpha=0.05
#init_ul_snr_value=5
#init_dl_cqi=5
#max_sib_coderate=0.3
#pdcch_cqi_offset=0
#nr_pdsch_mcs=28
#nr_pusch_mcs=28

#####################################################################
# Slicing configuration
#####################################################################
[slicing]
#enable_eMBB = false
#enable_URLLC = false
#enable_MIoT = false
#eMBB_sd = 1
#URLLC_sd = 1
#MIoT_sd = 1

#####################################################################
# eMBMS configuration options
#####################################################################
[embms]
#enable = false
#m1u_multiaddr = 239.255.0.1
#m1u_if_addr = 127.0.1.201
#mcs = 20

#####################################################################
# Channel emulator options
#####################################################################
[channel.dl]
#enable        = false

[channel.dl.awgn]
#enable        = false
#snr            = 30

[channel.dl.fading]
#enable        = false
#model         = none

[channel.dl.delay]
#enable        = false
#period_s      = 3600
#init_time_s   = 0
#maximum_us    = 100
#minimum_us    = 10

[channel.dl.rlf]
#enable        = false
#t_on_ms       = 10000
#t_off_ms      = 2000

[channel.dl.hst]
#enable        = false
#period_s      = 7.2
#fd_hz         = 750.0
#init_time_s   = 0.0

[channel.ul]
#enable        = false

[channel.ul.awgn]
#enable        = false
#n0            = -30

[channel.ul.fading]
#enable        = false
#model         = none

[channel.ul.delay]
#enable        = false
#period_s      = 3600
#init_time_s   = 0
#maximum_us    = 100
#minimum_us    = 10

[channel.ul.rlf]
#enable        = false
#t_on_ms       = 10000
#t_off_ms      = 2000

[channel.ul.hst]
#enable        = false
#period_s      = 7.2
#fd_hz         = -750.0

#####################################################################
# CFR configuration options
#####################################################################
[cfr]
#enable           = false
#mode             = manual
#manual_thres     = 0.5
#strength         = 1
#auto_target_papr = 8
#ema_alpha        = 0.0143

#####################################################################
# E2 Agent configuration options
#####################################################################
[e2_agent]
#enable = false
#ric_ip =  127.0.0.1
#ric_port = 36421
#ric_bind_ip =  127.0.0.1
#ric_bind_port = 36425
#max_ric_setup_retries = -1
#ric_connect_timer = 10

#####################################################################
# Expert configuration options
#####################################################################
[expert]
#pusch_max_its        = 8 # These are half iterations
#nr_pusch_max_its     = 10
#pusch_8bit_decoder   = false
#nof_phy_threads      = 3
#metrics_period_secs  = 1
#metrics_csv_enable   = false
#metrics_csv_filename = /tmp/enb_metrics.csv
#report_json_enable   = true
#report_json_filename = /tmp/enb_report.json
#report_json_asn1_oct = false
#alarms_log_enable    = true
#alarms_filename      = /tmp/enb_alarms.log
#tracing_enable       = true
#tracing_filename     = /tmp/enb_tracing.log
#tracing_buffcapacity = 1000000
#stdout_ts_enable     = false
#tx_amplitude         = 0.6
#rrc_inactivity_timer = 30000
#max_mac_dl_kos       = 100
#max_mac_ul_kos       = 100
#max_prach_offset_us  = 30
#nof_prealloc_ues     = 8
#rlf_release_timer_ms = 4000
#lcid_padding         = 3
#eea_pref_list = EEA0, EEA2, EEA1
#eia_pref_list = EIA2, EIA1, EIA0
#gtpu_tunnel_timeout = 0
#extended_cp         = false
#ts1_reloc_prep_timeout = 10000
#ts1_reloc_overall_timeout = 10000
#rlf_release_timer_ms = 4000
#rlf_min_ul_snr_estim = -2
#s1_setup_max_retries = -1
#s1_connect_timer = 10
#rx_gain_offset = 62
#mac_prach_bi         = 0
#use_cedron_f_est_alg = false
EOF

    # Create rr.conf aligned with project rr.conf
    sudo tee /etc/srsran/rr.conf > /dev/null <<EOF
mac_cnfg =
{
  phr_cnfg = 
  {
    dl_pathloss_change = "dB3"; // Valid: 1, 3, 6 or INFINITY
    periodic_phr_timer = 50;
    prohibit_phr_timer = 0;
  };
  ulsch_cnfg = 
  {
    max_harq_tx = 4;
    periodic_bsr_timer = 20; // in ms
    retx_bsr_timer = 320;   // in ms
  };
  
  time_alignment_timer = -1; // -1 is infinity
};

phy_cnfg =
{
  phich_cnfg = 
  {
    duration  = "Normal";
    resources = "1/6"; 
  };

  pusch_cnfg_ded =
  {
    beta_offset_ack_idx = 6;
    beta_offset_ri_idx  = 6;
    beta_offset_cqi_idx = 6;
  };
  
  // PUCCH-SR resources are scheduled on time-frequeny domain first, then multiplexed in the same resource. 
  sched_request_cnfg =
  {
    dsr_trans_max = 64;
    period = 20;          // in ms
    //subframe = [1, 11]; // Optional vector of subframe indices allowed for SR transmissions (default uses all)
    nof_prb = 1;          // number of PRBs on each extreme used for SR (total prb is twice this number)
  };
  cqi_report_cnfg =
  { 
    mode = "periodic";
    simultaneousAckCQI = true;
    period = 40;                   // in ms
    //subframe = [0, 10, 20, 30];  // Optional vector of subframe indices every period where CQI resources will be allocated (default uses all)
    m_ri = 8; // RI period in CQI period
    //subband_k = 1; // If enabled and > 0, configures sub-band CQI reporting and defines K (see 36.213 7.2.2). If disabled, configures wideband CQI
  };
};

cell_list =
(
  {
    // rf_port = 0;
    cell_id = 0x01;
    tac = 0x0007;
    pci = 1;
    // root_seq_idx = 204;
    dl_earfcn = 3740;
    //ul_earfcn = 21400;
    ho_active = false;
    //meas_gap_period = 0; // 0 (inactive), 40 or 80
    //meas_gap_offset_subframe = [6, 12, 18, 24, 30];
    // target_pusch_sinr = -1;
    // target_pucch_sinr = -1;
    // enable_phr_handling = false;
    // min_phr_thres = 0;
    // allowed_meas_bw = 6;
    // t304 = 2000; // in msec. possible values: 50, 100, 150, 200, 500, 1000, 2000
    // tx_gain = 20.0; // in dB. This gain is set by scaling the source signal.

    // CA cells
    scell_list = (
      // {cell_id = 0x02; cross_carrier_scheduling = false; scheduling_cell_id = 0x02; ul_allowed = true}
    )

    // Cells available for handover
    meas_cell_list =
    (
      {
        eci = 0x19B02;
        dl_earfcn = 3666;
        pci = 2;
        //direct_forward_path_available = false;
        //allowed_meas_bw = 6;
        //cell_individual_offset = 0;
      }
    );

    // Select measurement report configuration (all reports are combined with all measurement objects)
    meas_report_desc =
    (
        {
          eventA = 3
          a3_offset = 6;
          hysteresis = 0;
          time_to_trigger = 480;
          trigger_quant = "RSRP";
          max_report_cells = 1;
          report_interv = 120;
          report_amount = 1;
        }
    );
    meas_quant_desc = {
        // averaging filter coefficient
        rsrq_config = 4;
        rsrp_config = 4;
     };
  }
  // Add here more cells
);

nr_cell_list =
(
  // no NR cells
);
EOF

    # Create rb.conf aligned with project rb.conf
    sudo tee /etc/srsran/rb.conf > /dev/null <<EOF
// All times are in ms. Use -1 for infinity, where available

// 4G Section

qci_config = (
{
  qci = 7;
  pdcp_config = {
    discard_timer = -1;                
    pdcp_sn_size = 12;                  
  }
  rlc_config = {
    ul_um = {
      sn_field_length = 10; 
    };
    dl_um = {
      sn_field_length = 10; 
      t_reordering    = 45;             
    };
  };
  logical_channel_config = {
    priority = 13; 
    prioritized_bit_rate   = -1; 
    bucket_size_duration  = 100; 
    log_chan_group = 2; 
  };
  enb_specific = {
    dl_max_retx_thresh = 32;
  };
},
{
  qci = 9;
  pdcp_config = {
    discard_timer = 150;
    status_report_required = true;
  }
  rlc_config = {
    ul_am = {
      t_poll_retx = 120;
      poll_pdu = 64;
      poll_byte = 750;
      max_retx_thresh = 16;
    };
    dl_am = {
      t_reordering = 50;
      t_status_prohibit = 50;
    };
  };
  logical_channel_config = {
    priority = 11; 
    prioritized_bit_rate   = -1; 
    bucket_size_duration  = 100; 
    log_chan_group = 3; 
  };
  enb_specific = {
    dl_max_retx_thresh = 32;
  };
}
);

// 5G Section
srb1_5g_config = {
 rlc_config = {
   ul_am = {
     sn_field_len = 12;
     t_poll_retx = 45;
     poll_pdu = -1;
     poll_byte = -1;
     max_retx_thres = 8;
   };
   dl_am = {
     sn_field_len = 12;
     t_reassembly = 35;
     t_status_prohibit = 10;
   };
 };
}

srb2_5g_config = {
 rlc_config = {
   ul_am = {
     sn_field_len = 12;
     t_poll_retx = 45;
     poll_pdu = -1;
     poll_byte = -1;
     max_retx_thres = 8;
   };
   dl_am = {
     sn_field_len = 12;
     t_reassembly = 35;
     t_status_prohibit = 10;
   };
 };
}

five_qi_config = (
{
  five_qi = 7;
  pdcp_nr_config = {
    drb = {
      pdcp_sn_size_ul = 18;
      pdcp_sn_size_dl = 18;
      discard_timer = 50;
      integrity_protection = false;
      status_report = false;
    };
    t_reordering = 50;
  };
  rlc_config = {
    um_bi_dir = {
      ul_um = {
        sn_field_len = 12;
      };
      dl_um = {
        sn_field_len = 12;
        t_reassembly = 50;
      };
    };
  };
},
{
  five_qi = 9;
  pdcp_nr_config = {
    drb = {
      pdcp_sn_size_ul = 18;
      pdcp_sn_size_dl = 18;
      discard_timer = 50;
      integrity_protection = false;
      status_report = false;
    };
    t_reordering = 50;
  };
  rlc_config = {
    am = {
      ul_am = {
        sn_field_len = 12;
        t_poll_retx = 50;
        poll_pdu = 4;
        poll_byte = 3000;
        max_retx_thres = 4;
      };
      dl_am = {
        sn_field_len = 12;
        t_reassembly = 50;
        t_status_prohibit = 50;
      };
    };
  };
}
);
EOF

    # Create sib.conf aligned with project sib.conf
    sudo tee /etc/srsran/sib.conf > /dev/null <<EOF
#####################################################################
# sib1 configuration options (See TS 36.331)
#
# additional_plmns: A list of additional PLMN identities.
#     mcc: MCC
#     mnc: MNC
#     cell_reserved_for_oper:  One of "reserved" or "notReserved", default is "notReserved"
#
#####################################################################
sib1 =
{
    intra_freq_reselection = "Allowed";
    q_rx_lev_min = -65;
    //p_max = 3;
    cell_barred = "NotBarred"
    si_window_length = 20;
    sched_info =
    (
        {
            si_periodicity = 16;

            // comma-separated array of SIB-indexes (from 3 to 13), leave empty or commented to just scheduler sib2
            si_mapping_info = [ 3 ];
        }
    );
    system_info_value_tag = 0;
};

sib2 = 
{
    rr_config_common_sib =
    {
        rach_cnfg = 
        {
            num_ra_preambles = 52;
            preamble_init_rx_target_pwr = -104;
            pwr_ramping_step = 6;  // in dB
            preamble_trans_max = 10;
            ra_resp_win_size = 10;  // in ms
            mac_con_res_timer = 64; // in ms
            max_harq_msg3_tx = 4;
        };
        bcch_cnfg = 
        {
            modification_period_coeff = 16; // in ms
        };
        pcch_cnfg = 
        {
            default_paging_cycle = 32; // in rf
            nB = "1";
        };
        prach_cnfg =
        {
            root_sequence_index = 128;
            prach_cnfg_info =
            {
                high_speed_flag = false;
                prach_config_index = 3;
                prach_freq_offset = 4;
                zero_correlation_zone_config = 5;
            };
        };
        pdsch_cnfg = 
        {
            /* Warning: Currently disabled and forced to p_b=1 for TM2/3/4 and p_b=0 for TM1
             */
            p_b = 1;
            rs_power = 0;
        };
        pusch_cnfg = 
        {
            n_sb = 1;
            hopping_mode = "inter-subframe";
            pusch_hopping_offset = 2;
            enable_64_qam = false; // 64QAM PUSCH is not currently enabled
            ul_rs = 
            {
                cyclic_shift = 0; 
                group_assignment_pusch = 0;
                group_hopping_enabled = false; 
                sequence_hopping_enabled = false; 
            };
        };
        pucch_cnfg =
        {
            delta_pucch_shift = 1;
            n_rb_cqi = 1;
            n_cs_an = 0;
            n1_pucch_an = 12;
        };
        ul_pwr_ctrl =
        {
            p0_nominal_pusch = -85;
            alpha = 0.7;
            p0_nominal_pucch = -107;
            delta_flist_pucch =
            {
                format_1  = 0;
                format_1b = 3; 
                format_2  = 1;
                format_2a = 2;
                format_2b = 2;
            };
            delta_preamble_msg3 = 6;
        };
        ul_cp_length = "len1";
    };

    ue_timers_and_constants =
    {
        t300 = 2000; // in ms
        t301 = 100;  // in ms
        t310 = 200; // in ms
        n310 = 1;
        t311 = 10000; // in ms
        n311 = 1;
    };

    freqInfo = 
    {
        ul_carrier_freq_present = true; 
        ul_bw_present = true; 
        additional_spectrum_emission = 1; 
    };

    time_alignment_timer = "INFINITY"; // use "sf500", "sf750", etc.
};

sib3 =
{
    cell_reselection_common = {
        q_hyst = 2; // in dB
    },
    cell_reselection_serving = {
        s_non_intra_search = 3,
        thresh_serving_low = 2,
        cell_resel_prio = 6
    },
    intra_freq_reselection = {
        q_rx_lev_min = -61,
        p_max = 23,
        s_intra_search = 5,
        presence_ant_port_1 = true,
        neigh_cell_cnfg = 1,
        t_resel_eutra = 1
    }
};

#####################################################################
# sib5 configuration options (See TS 36.331)
#####################################################################
sib5 =
{
    inter_freq_carrier_freq_list =
    (
        {
            dl_carrier_freq = 1450;
            q_rx_lev_min = -70;
            t_resel_eutra = 2;
            t_resel_eutra_sf = {
                sf_medium = "0.25";
                sf_high = "1.0";
            };
            thresh_x_high = 3;
            thresh_x_low = 2;
            allowed_meas_bw = 75;
            presence_ant_port_1 = True;
            cell_resel_prio = 4;
            neigh_cell_cfg = 2;
            q_offset_freq = -6;
            inter_freq_neigh_cell_list =
            (
                {
                    phys_cell_id = 500;
                    q_offset_cell = 2;
                }
            );
            inter_freq_black_cell_list =
            (
                {
                    start = 123;
                    range = 4;
                }
            );
        }
    );
};

#####################################################################
# sib6 configuration options (See TS 36.331)
#####################################################################
sib6 =
{
    t_resel_utra = 1;
    t_resel_utra_sf = {
        sf_medium = "0.25";
        sf_high = "1.0";
    }
    carrier_freq_list_utra_fdd =
    (
        {
            carrier_freq = 9613;
            cell_resel_prio = 6;
            thresh_x_high = 3;
            thresh_x_low = 2;
            q_rx_lev_min = -50;
            p_max_utra = 4;
            q_qual_min = -10;
        }
    );
    carrier_freq_list_utra_tdd =
    (
        {
            carrier_freq = 9505;
            thresh_x_high = 1;
            thresh_x_low = 2;
            q_rx_lev_min = -50;
            p_max_utra = -3;
        }
    );
};

#####################################################################
# sib7 configuration options (See TS 36.331)
#####################################################################
sib7 =
{
    t_resel_geran = 1;
    carrier_freqs_info_list =
    (
        {
            cell_resel_prio = 0;
            ncc_permitted = 255;
            q_rx_lev_min = 0;
            thresh_x_high = 2;
            thresh_x_low = 2;

            start_arfcn = 871;
            band_ind = "dcs1800";
            explicit_list_of_arfcns = (
                871
            );
        }
    );
};
EOF
}

# Clone and build srsRAN 4G
echo "Cloning and building srsRAN 4G..."
cd /tmp
rm -rf srsRAN_4G
git clone https://github.com/srsran/srsRAN_4G.git
cd srsRAN_4G
mkdir build && cd build
cmake ../
make -j$(nproc)
sudo make install
sudo ldconfig

# Create srsRAN configuration directory
sudo mkdir -p /etc/srsran

# Configure eNodeB using user-editable configuration files
echo "Configuring eNodeB with user-editable configuration files..."

# Check if user wants to use existing config files
if [[ "${USE_EXISTING_CONF:-0}" == "1" ]]; then
    echo "Using existing configuration files in /etc/srsran/"
    if [ ! -f "/etc/srsran/enb.conf" ]; then
        echo "Warning: /etc/srsran/enb.conf not found, creating default configuration..."
        configure_srsran_4g
    fi
else
    # Try to copy example configurations first
    cd /tmp/srsRAN_4G

    if [ -d "srsenb" ]; then
        echo "Copying example configuration files from srsenb/..."

        # Copy example config files as templates
        sudo cp srsenb/enb.conf.example /etc/srsran/enb.conf 2>/dev/null || sudo cp srsenb/enb.conf /etc/srsran/ 2>/dev/null || true
        sudo cp srsenb/rr.conf.example /etc/srsran/rr.conf 2>/dev/null || sudo cp srsenb/rr.conf /etc/srsran/ 2>/dev/null || true
        sudo cp srsenb/rb.conf.example /etc/srsran/rb.conf 2>/dev/null || sudo cp srsenb/rb.conf /etc/srsran/ 2>/dev/null || true
        sudo cp srsenb/sib.conf.example /etc/srsran/sib.conf 2>/dev/null || sudo cp srsenb/sib.conf /etc/srsran/ 2>/dev/null || true
    fi

    # Apply LibreSDR/Open5GS specific modifications
    if [ -f "/etc/srsran/enb.conf" ]; then
        echo "Applying LibreSDR and Open5GS configuration..."

        # Modify enb.conf for LibreSDR and Open5GS
        sudo sed -i 's/mme_addr = 127.0.1.100/mme_addr = 127.0.1.2/' /etc/srsran/enb.conf 2>/dev/null || true
        sudo sed -i 's/gtp_bind_addr = 127.0.0.1/gtp_bind_addr = 127.0.1.1/' /etc/srsran/enb.conf 2>/dev/null || true
        sudo sed -i 's/s1c_bind_addr = 127.0.0.1/s1c_bind_addr = 127.0.1.1/' /etc/srsran/enb.conf 2>/dev/null || true

        # Add or update LibreSDR device configuration
        if ! grep -q "device_name = UHD" /etc/srsran/enb.conf; then
            echo "" | sudo tee -a /etc/srsran/enb.conf > /dev/null
            echo "[rf]" | sudo tee -a /etc/srsran/enb.conf > /dev/null
            echo "device_name = UHD" | sudo tee -a /etc/srsran/enb.conf > /dev/null
            echo "device_args = type=b200,num_recv_frames=64,num_send_frames=64" | sudo tee -a /etc/srsran/enb.conf > /dev/null
            # Only add gain settings if they don't already exist
            if ! grep -q "^tx_gain = " /etc/srsran/enb.conf; then
                echo "tx_gain = 80" | sudo tee -a /etc/srsran/enb.conf > /dev/null
            fi
            if ! grep -q "^rx_gain = " /etc/srsran/enb.conf; then
                echo "rx_gain = 40" | sudo tee -a /etc/srsran/enb.conf > /dev/null
            fi
        else
            # Ensure LibreSDR device args are set
            if ! grep -q "device_args = type=b200" /etc/srsran/enb.conf; then
                sudo sed -i '/device_name = UHD/a device_args = type=b200,num_recv_frames=64,num_send_frames=64' /etc/srsran/enb.conf
            fi
        fi

        # Modify rr.conf for Band 8 (900 MHz)
        if [ -f "/etc/srsran/rr.conf" ]; then
            sudo sed -i 's/dl_earfcn = [0-9]\+/dl_earfcn = 3740/' /etc/srsran/rr.conf 2>/dev/null || true
        fi

        echo "Configuration files ready for editing:"
        echo "  📝 /etc/srsran/enb.conf - Main eNodeB configuration"
        echo "  📝 /etc/srsran/rr.conf - Radio Resources configuration"
        echo "  📝 /etc/srsran/rb.conf - Radio Bearer configuration"
        echo "  📝 /etc/srsran/sib.conf - System Information Block configuration"
        echo ""
        echo "You can now edit these files directly to customize your setup!"
        echo "Example commands:"
        echo "  sudo nano /etc/srsran/enb.conf    # Edit main config"
        echo "  sudo nano /etc/srsran/rr.conf     # Edit radio resources"
        echo ""
        echo "Key configuration options you can modify:"
        echo "  • MME address (mme_addr)"
        echo "  • Cell frequency (dl_earfcn in rr.conf)"
        echo "  • TX/RX gain (tx_gain, rx_gain)"
        echo "  • MCC/MNC codes"
        echo "  • Cell ID, PCI, TAC values"
    else
        echo "No example config files found, creating custom configuration..."
        configure_srsran_4g
    fi
fi

echo ""
echo "🎉 srsRAN 4G installation and configuration completed!"
echo ""
echo "📁 Configuration files location: /etc/srsran/"
echo "🚀 To run eNodeB: sudo srsenb /etc/srsran/enb.conf"
echo "🔧 To modify configuration: sudo nano /etc/srsran/enb.conf"
echo ""
echo "💡 Environment Variables:"
echo "   USE_EXISTING_CONF=1  # Use existing config files without modifications"
echo ""
echo "📖 Example usage:"
echo "   USE_EXISTING_CONF=1 ./srsran-4g.sh  # Use your custom configs"
echo ""
echo "🛠️  Helper commands:"
echo "   ./edit-srsran-config.sh             # Interactive config editor"
echo "   sudo srsenb /etc/srsran/enb.conf    # Run eNodeB"
echo "   sudo srsue /etc/srsran/ue.conf      # Run UE (if configured)"
