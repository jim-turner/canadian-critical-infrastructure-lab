PROGRAM CMWTF01_MultiStage_Plant
  VAR
    raw_tank_level AT %QW0 : INT;
    turbidity_ntu AT %QW1 : INT;
    chlorine_ppm AT %QW2 : INT;
    clean_tank_level AT %QW3 : INT;
    dist_flow_lpm AT %QW4 : INT;

    high_level_alarm AT %QX0.0 : BOOL;
    intake_pump_cmd AT %QX0.1 : BOOL;
    transfer_valve_cmd AT %QX0.2 : BOOL;
    dist_pump_cmd AT %QX0.3 : BOOL;
    low_level_alarm AT %QX0.4 : BOOL;
  END_VAR

  VAR
    scan_div : INT := 0;
    initialized : BOOL := FALSE;
  END_VAR

  (* First-scan initialization for located Modbus registers & coils *)
  IF NOT initialized THEN
    raw_tank_level := 400;
    turbidity_ntu := 12;
    chlorine_ppm := 180;
    clean_tank_level := 500;
    dist_flow_lpm := 80;

    high_level_alarm := FALSE;
    intake_pump_cmd := FALSE;
    transfer_valve_cmd := TRUE;
    dist_pump_cmd := TRUE;
    low_level_alarm := FALSE;
    initialized := TRUE;
  END_IF;

  scan_div := scan_div + 1;
  IF scan_div >= 10 THEN
    scan_div := 0;

    (* 1. Raw Water Intake -> Raw Reservoir (+15 L/sec when pumping) *)
    IF intake_pump_cmd AND (raw_tank_level < 950) THEN
      raw_tank_level := raw_tank_level + 15;
    END_IF;

    (* 2. Filtration & Chemical Dosing -> Clean Clearwell (10 L/sec transfer) *)
    IF transfer_valve_cmd AND (raw_tank_level >= 15) AND (clean_tank_level < 950) THEN
      raw_tank_level := raw_tank_level - 10;
      clean_tank_level := clean_tank_level + 10;
      turbidity_ntu := 12;
      chlorine_ppm := 185;
    ELSE
      IF turbidity_ntu < 45 THEN
        turbidity_ntu := turbidity_ntu + 3;
      END_IF;
      IF chlorine_ppm > 20 THEN
        chlorine_ppm := chlorine_ppm - 2;
      END_IF;
    END_IF;

    (* 3. Municipal Distribution Demand -> Outflow (-8 L/sec when pumping) *)
    IF dist_pump_cmd AND (clean_tank_level >= 10) THEN
      clean_tank_level := clean_tank_level - 8;
      dist_flow_lpm := 80;
    ELSE
      dist_flow_lpm := 0;
    END_IF;
  END_IF;

  (* 4. Hardwired PLC High-Level Overflow Interlocks *)
  IF (raw_tank_level >= 950) OR (clean_tank_level >= 950) THEN
    high_level_alarm := TRUE;
    intake_pump_cmd := FALSE;
    transfer_valve_cmd := FALSE;
  ELSE
    high_level_alarm := FALSE;
  END_IF;

  (* 5. Hardwired PLC Low-Level Pump Dry-Run Protection *)
  IF (clean_tank_level <= 15) THEN
    low_level_alarm := TRUE;
    dist_pump_cmd := FALSE;
  ELSE
    low_level_alarm := FALSE;
  END_IF;
END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#100ms, PRIORITY := 0);
    PROGRAM instance0 WITH task0 : CMWTF01_MultiStage_Plant;
  END_RESOURCE
END_CONFIGURATION
