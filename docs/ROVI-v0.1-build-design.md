# ROVI v0.1 — build specification
Status: reference design for prototyping, not a validated assembly or purchase order. Tracks #8 and #12. Weekly effort: 6–8 hours. First integrated release: #23.

## Demo contract
Start stationary with blinking eyes. Hold laptop arrow keys to drive and turn; release stops. Explicitly select Follow. Present printed marker ID 7: eyes look toward it, base turns to center it and slowly approaches a comfortable distance. Remove the card: motion stops. Insert an obstacle: stop and show alert. Disconnect laptop: motors stop without any host software running. Reconnect: no automatic restart. Demonstrate first on floor, then on a protected desk. No general object recognition, route planning, roaming, voice or phone requirement for this release.

## Physical design
Custom two-wheel differential drive. Target 110 mm wide × 130 mm long INCLUDING wheels; height target 85 mm. Start with a full-size cardboard mockup before printing. Use two side-mounted 6 V N20-class encoder motors with approximately 32 mm wheels, axle near the center of mass, rear ball caster. Place cells flat and low near axle; robot must rest stably with all wheels in contact across expected accelerations. Put camera near front center, above the eye display, facing straight forward; front range sensor below display with unobstructed field of view. Four downward reflectance sensors near corners, ahead of the wheel/caster contact points in their respective directions. Mock up actual swept paths during pivots: four sensors alone do not establish coverage.
Print three serviceable pieces at NCSU: open base plate, removable sensor brackets, face/camera upright. Initial CAD targets: 3 mm plate and 2.5 mm upright, slotted motor brackets and cable ties. Keep USB ports, physical switch and batteries accessible. Use a paper template of each exact breakout, wheel hub, connector bend and battery holder; drill/print final holes only after checking fit. Print a single sensor bracket first to tune height. Add decorative shell only after edge tests.

## Procurement worksheet (USD allocation, not quotes)
|Qty|Reference choice and function|Target allocation|
|---|---|---:|
|2 + pair|Matched 6 V micro gearmotors with quadrature encoders, compatible wheels and hubs|45|
|1 each|RP2040 Pico-class board for safety; dual TB6612FNG-class motor driver, conditional on motor current|16|
|1|XIAO ESP32S3 Sense camera board: Wi-Fi camera stream and host link|20|
|1|Small I²C SSD1306 OLED for monochrome eyes|10|
|4 + 1|Independent 3.3 V-compatible downward RC reflectance channels; front VL53L0X breakout|35|
|1 set|4×AA NiMH cells, holder, external matched charger, switch, fuse, regulated 5 V buck-boost supply|45|
|1 set|Caster, mounts, filament, capacitors, wire, connectors, fasteners|15|
| |Hardware allowance before shipping/tax|186|

Target $200; review full delivered cart before going above it; proposed ceiling $250. No purchases yet. Assumes laptop, access to soldering iron, multimeter and basic hand tools; printer access alone does not establish tool access. Compare two carts: target-cost encoder motors with published stall current vs. Pololu reference at $29.95 each (adds $14.90 to motor allocation before wheel costs). An integrated Pololu 3pi+ Turtle kit costs $179.95 before the camera and extras; it fits the footprint but leaves little budget for upgrades and replaces much of the custom chassis work. Prefer custom base for this build.
Price anchors and documentation: [Pololu motor](https://www.pololu.com/product/5168), [integrated kit](https://www.pololu.com/product/5005/specs), [front sensor](https://www.adafruit.com/product/3317), [camera board family](https://www.seeedstudio.com/xiao-series-page/products/). Confirm actual stock, connectors, voltage, mounting drawings and delivered prices before ordering.

## Electrical design / wiring schedule
Switched and fused battery → parallel branches: driver VM (motor supply), and regulated 5 V logic supply. Common ground; motor return should not run through controller ground traces. Feed Pico VSYS and camera board only via documented supported power inputs. Size regulator for simultaneous camera radio peaks and peripheral load; measure under both motors starting. Budget motor current from the actual motor datasheet at highest pack voltage; select a driver/fuse/wire/holder combination that tolerates startup and handles stalls. Do not rely on peak driver ratings or run untested high-current motor paths through a solderless breadboard. Do not connect external 5 V and USB simultaneously until the power isolation path is verified. Charge cells outside the robot in the matched charger.

Proposed standard Pico GPIO numbers (not physical header pin numbers):
|Pins|Connection|
|---|---|
|GP0 TX / GP1 RX|3.3 V UART crossed to free camera-board RX/TX respectively; verify camera expansion-board pin conflicts and common ground|
|GP2/3/4|Motor A direction 1/2, PWM|
|GP5/6/7|Motor B direction 1/2, PWM|
|GP8|Driver STBY with hardware pull-down; reset defaults to disabled|
|GP9–12|Left encoder A/B, right encoder A/B; verify output voltage, add level shifting when required|
|GP13–16|Four independent downward RC sensor signals; calibrate with actual floor/desk|
|GP18 SDA / GP19 SCL|I²C1 OLED and front range breakout; pull-ups to 3.3 V, verify distinct addresses|
|GP17|Physical arm/reset button to ground with pull-up|
|GP26 ADC|Optional pack monitor through calculated divider; validate ADC range at maximum pack voltage|

Use the driver's specified local bypass/bulk capacitors and motor noise suppression. Keep encoder and sensor wiring away from motor leads. Before soldering, make a physical-header-to-signal pinout for the purchased board revisions. Verify continuity and rails without motors, then test one motor with wheels lifted. A motor-driver substitute may require a different pin map.

## Software, messages and ownership
Robot: Pico owns encoder feedback, wheel control, command expiry, local safety and face rendering. ESP32 owns camera acquisition, Wi-Fi and UART forwarding. Laptop: ROS 2 Jazzy nodes for camera/bridge, marker perception, keyboard teleoperation, follow controller, movement arbitration and status display. Simulation substitutes a fake base behind the same command/status interface. Only the arbiter sends motion to the bridge; the Pico can veto it at any time. Firmware must continue polling safety and watchdog timers if display updates or range reads fail.
- Camera → laptop: timestamp/sequence + compressed frame; initial goal 320×240 at 10 fps. Measure end-to-end age; do not treat network arrival time as capture time. Establish clock offset or bound latency independently.
- Operator → arbiter: manual dead-man input or explicit start/cancel follow. Priority: stop > manual > autonomous. Mode change first commands zero.
- Tracker → follow: marker ID, horizontal error, estimated distance, observation time and validity.
- Host → bridge → Pico: version, session ID, sequence, mode, linear m/s, angular rad/s, short expiry. Start with 20 Hz commands and a 250 ms MCU watchdog. Reject stale, queued, replayed, malformed and out-of-range commands. Session handshake/clock alignment or receiver-issued expiring command grants required; sequence alone does not detect delayed packets. Reboot/disconnect invalidates session. Use authenticated local network control; no Internet-facing endpoint.
- Pico → host: measured wheel speeds/ticks, sensor validity and readings, arm/safety state, stop reason, active command sequence. Log timestamps and mode transitions.
- Differential drive: desired wheel linear speeds are v − ωb/2 and v + ωb/2 for track width b. Divide by measured wheel radius for angular speed; bounded feedback from each encoder. Start at 0.04 m/s on protected trials; any later increase needs fresh stopping measurements.

## Tracking and personality
Print one 50 mm square ArUco (DICT_4X4_50, ID 7); measure the black square after printing. Calibrate camera intrinsics at the actual stream resolution. Use corner geometry and known side length for pose; reject bad corner fits, implausible jumps, wrong IDs or stale frames. Start with rotation only. When centered within a proposed ±8° band, allow slow forward approach. Initial target distance 25 cm with ±5 cm deadband. If too close, stop; do not reverse autonomously. Keep obstacle sensing independent of target range. Start the front stop threshold around 12 cm for bench evaluation; actual threshold must exceed measured stopping distance plus uncertainty. Marker occlusion or expired frames command zero; deliberate restart for prototype. Test against a ruler at several distances and angles before enabling approach.
Eyes: idle blink → attentive on follow enable → glance toward marker based on horizontal error → cheerful when centered. Lost target: puzzled and stationary. Hazard or disconnected: local alert takes priority over host expressions. No emotion recognition or moving head.

## Release checks (proposed criteria; no tests claimed)
|Test|Pass condition / evidence|
|---|---|
|Startup, reset, laptop or radio loss|Zero drive on startup; motor outputs inhibited within watchdog deadline after last valid command; reconnect does not move. Record output timing AND physical stopping travel.|
|Manual controls|Key release, cancel, mode switch and conflicting sources produce expected stop/priority in logs; reverse only on verified surfaces/directions.|
|Edge coverage|Use a tether/catch tray. Test each enabled approach direction, oblique approaches and pivots at maximum permitted speed, including low battery and each intended surface. At least 10 repeats per worst-case condition. No wheel/caster crosses edge. Worst travel after first reliable detection plus position/measurement uncertainty must be below available contact-point margin. Disable any unproven direction or surface.|
|Obstacle|Broad target at center and near sensor field boundary. Stop before contact in every declared test case. Record blind zones; V1 may operate only within tested geometry. No detours.|
|Following|At fixed lighting and calibrated size, turn toward correct ID in both directions, then settle at 20–30 cm in 9 of 10 floor trials. Wrong ID, frozen video or removal never causes forward pursuit.|
|Power and faults|Measure rails under startup/turn load; no unintended reset or motion. Sensor disconnect/invalid timestamp forces inhibition. Test physical power switch with wheels lifted.|
|Integrated demo|Record idle → manual → follow → obstacle stop → operator re-arm → target loss → connection loss. Keep protected tabletop setup until mechanical and sensor margins are demonstrated.|

## Build sequence and purchase gates
1. Week-one session (6–8 h): 2 h measure desk and mock up footprint; 2 h print/measure marker and capture laptop-webcam clips; 2–4 h animate eyes and demonstrate idle/tracking/lost states on laptop. No hardware purchase required.
2. Freeze dimensioned parts layout, pinout, current budget and delivered cart. Resolve availability of tools and access to charger before ordering. Start with base/control/power; defer cosmetic parts.
3. Bring up one motor, then both encoders, watchdog and floor driving. Measure actual wheel radius, track width and maximum stop travel.
4. Calibrate edge and obstacle sensors; complete protected safety trials before tabletop following.
5. Switch to robot camera, calibrate pose, connect following and expressions; run integrated release checks. Keep one feature active at a time in GitHub Issues.
6. Future: same host contract for phone remote, then benchmark and port the minimum perception/control session to phone. Mapping, obstacle detours and additional target classes are separate modules.

## Outstanding before fabrication
Exact motor/driver pair, battery holder fit, rail current peaks, camera UART pins, wheel/caster geometry, surface-specific sensor placement, delivered BOM, and fabrication tolerances. Do not freeze final hole locations or claim an exact speed/edge guarantee until measured.
