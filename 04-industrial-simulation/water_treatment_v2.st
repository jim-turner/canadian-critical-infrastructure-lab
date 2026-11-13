PROGRAM prog0
VAR
  counter AT %MW0 : INT := 0;
  toggle AT %QX0.0 : BOOL := FALSE;
  pump_cmd AT %QX0.1 : BOOL := FALSE;
END_VAR

counter := counter + 1;
IF counter > 1000 THEN
  counter := 0;
  toggle := NOT toggle;
END_IF;
END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#500ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : prog0;
  END_RESOURCE
END_CONFIGURATION
