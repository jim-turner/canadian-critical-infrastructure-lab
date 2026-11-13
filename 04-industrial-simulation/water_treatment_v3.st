PROGRAM prog0
VAR
  tank_level AT %MW0 : INT := 500;
  high_level_alarm AT %QX0.0 : BOOL := FALSE;
  pump_cmd AT %QX0.1 : BOOL := FALSE;
END_VAR

(* 1. Pump Inflow vs. Municipal Outflow Physics (500ms scan cycle) *)
IF pump_cmd THEN
  tank_level := tank_level + 5;
END_IF;

(* Constant municipal water demand drains 2 units per scan *)
tank_level := tank_level - 2;

(* 2. Clamp Tank Level within Physical Bounds (0 to 1000) *)
IF tank_level < 0 THEN
  tank_level := 0;
ELSIF tank_level > 1000 THEN
  tank_level := 1000;
END_IF;

(* 3. High-Water Safety Interlock (Trips pump at >= 950) *)
IF tank_level >= 950 THEN
  high_level_alarm := TRUE;
  pump_cmd := FALSE;
ELSE
  high_level_alarm := FALSE;
END_IF;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#500ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : prog0;
  END_RESOURCE
END_CONFIGURATION
