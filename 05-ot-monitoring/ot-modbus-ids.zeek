@load base/frameworks/notice
@load base/protocols/modbus

module OT_Modbus_IDS;

export {
    redef enum Notice::Type += {
        ## Fired when a non-HMI IP issues a Modbus write command
        Unauthorized_Modbus_Write,
        ## Fired when any device attempts to write to protected safety coil 0 (%QX0.0)
        Safety_Interlock_Tampering,
        ## Fired when any device attempts to overwrite sensor holding registers (%MW0)
        Sensor_Register_Spoofing
    };

    ## Authorized HMI IP address
    const authorized_hmi: addr = 10.0.30.20 &redef;
}

# 1. Detect unauthorized single-coil writes (FC 5) or safety interlock tampering
event modbus_write_single_coil_request(c: connection, headers: ModbusHeaders, address: count, value: bool)
    {
    local src = c$id$orig_h;
    local dst = c$id$resp_h;

    # Flag any write coming from an IP other than the Node-RED HMI
    if ( src != authorized_hmi )
        {
        NOTICE([
            $note=Unauthorized_Modbus_Write,
            $conn=c,
            $msg=fmt("Unauthorized Modbus FC5 Write Single Coil from %s to PLC %s (Coil %d -> %s)", src, dst, address, value),
            $identifier=cat(src, dst, address)
        ]);
        }

    # Flag any attempt to write directly to Coil 0 (high_level_alarm %QX0.0)
    if ( address == 0 )
        {
        NOTICE([
            $note=Safety_Interlock_Tampering,
            $conn=c,
            $msg=fmt("CRITICAL: Attempt to overwrite High-Water Alarm Coil 0 from %s (value=%s)", src, value),
            $identifier=cat(src, "coil0")
        ]);
        }
    }

# 2. Detect unauthorized multi-coil writes (FC 15)
event modbus_write_multiple_coils_request(c: connection, headers: ModbusHeaders, start_address: count, coils: ModbusCoils)
    {
    local src = c$id$orig_h;
    if ( src != authorized_hmi )
        {
        NOTICE([
            $note=Unauthorized_Modbus_Write,
            $conn=c,
            $msg=fmt("Unauthorized Modbus FC15 Write Multiple Coils from %s to PLC %s (Start Addr %d)", src, c$id$resp_h, start_address),
            $identifier=cat(src, c$id$resp_h, "fc15")
        ]);
        }
    }

# 3. Detect unauthorized holding register overwrites (FC 6 / FC 16 - tank_level %MW0)
event modbus_write_single_register_request(c: connection, headers: ModbusHeaders, address: count, value: count)
    {
    NOTICE([
        $note=Sensor_Register_Spoofing,
        $conn=c,
        $msg=fmt("CRITICAL: Attempt to spoof Holding Register %d (value=%d) on PLC %s from %s", address, value, c$id$resp_h, c$id$orig_h),
        $identifier=cat(c$id$orig_h, address)
    ]);
    }
