@load base/frameworks/notice
@load base/protocols/modbus

module OT_Modbus_IDS;

export {
    redef enum Notice::Type += {
        ## Stage 1: Discovery - Non-HMI host reading coils/registers or probing device ID
        Unauthorized_Modbus_Recon,
        ## Stage 2: Impair Process Control - Unauthorized write from non-HMI IP
        Unauthorized_Modbus_Write,
        ## Stage 3: Inhibit Response Function - Tampering with safety alarm coil 0
        Safety_Interlock_Tampering,
        ## Stage 4: Manipulation of Control - Spoofing tank level holding register
        Sensor_Register_Spoofing,
        ## Rapid write burst detection (anti-automation / replay indicator)
        Rapid_Modbus_Write_Burst
    };

    const authorized_hmi: addr = 10.0.30.20 &redef;
    global write_counter: table[addr] of count &default=0 &create_expire=10sec;
}

# Stage 1: Detect Modbus Coil/Register Enumeration from unauthorized IPs (T0801 / T0846)
event modbus_read_coils_request(c: connection, headers: ModbusHeaders, start_address: count, quantity: count)
    {
    if ( c$id$orig_h != authorized_hmi )
        {
        NOTICE([
            $note=Unauthorized_Modbus_Recon,
            $conn=c,
            $msg=fmt("MITRE T0801 Discovery: Non-HMI IP %s enumerated Coils (start=%d, qty=%d) on PLC %s", c$id$orig_h, start_address, quantity, c$id$resp_h),
            $identifier=cat(c$id$orig_h, "read_coils")
        ]);
        }
    }

event modbus_read_holding_registers_request(c: connection, headers: ModbusHeaders, start_address: count, quantity: count)
    {
    if ( c$id$orig_h != authorized_hmi )
        {
        NOTICE([
            $note=Unauthorized_Modbus_Recon,
            $conn=c,
            $msg=fmt("MITRE T0801 Discovery: Non-HMI IP %s enumerated Holding Registers (start=%d, qty=%d) on PLC %s", c$id$orig_h, start_address, quantity, c$id$resp_h),
            $identifier=cat(c$id$orig_h, "read_hr")
        ]);
        }
    }

# Track rapid write bursts across any source IP (including a compromised HMI)
function track_write_rate(c: connection)
    {
    local src = c$id$orig_h;
    ++write_counter[src];
    if ( write_counter[src] >= 5 )
        {
        NOTICE([
            $note=Rapid_Modbus_Write_Burst,
            $conn=c,
            $msg=fmt("MITRE T0855 Anomaly: Rapid Modbus write burst (%d writes in 10s) from %s to PLC %s", write_counter[src], src, c$id$resp_h),
            $identifier=cat(src, "burst")
        ]);
        }
    }

# Stage 2 & 3: Unauthorized Coil Writes & Safety Interlock Tampering (T0855 / T0878)
event modbus_write_single_coil_request(c: connection, headers: ModbusHeaders, address: count, value: bool)
    {
    local src = c$id$orig_h;
    local dst = c$id$resp_h;
    track_write_rate(c);

    if ( src != authorized_hmi )
        {
        NOTICE([
            $note=Unauthorized_Modbus_Write,
            $conn=c,
            $msg=fmt("MITRE T0855 Unauthorized Command: Non-HMI %s wrote Coil %d -> %s on PLC %s", src, address, value, dst),
            $identifier=cat(src, dst, address)
        ]);
        }

    if ( address == 0 )
        {
        NOTICE([
            $note=Safety_Interlock_Tampering,
            $conn=c,
            $msg=fmt("MITRE T0878 Inhibit Response: Attempt to overwrite High-Water Alarm Coil 0 (value=%s) from %s", value, src),
            $identifier=cat(src, "coil0")
        ]);
        }
    }

# Stage 4: Sensor Holding Register Spoofing (T0836 - Modify Parameter)
event modbus_write_single_register_request(c: connection, headers: ModbusHeaders, address: count, value: count)
    {
    track_write_rate(c);
    NOTICE([
        $note=Sensor_Register_Spoofing,
        $conn=c,
        $msg=fmt("MITRE T0836 Modify Parameter: Attempt to overwrite Holding Register %d (value=%d) on PLC %s from %s", address, value, c$id$resp_h, c$id$orig_h),
        $identifier=cat(c$id$orig_h, address)
    ]);
    }
