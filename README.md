<<<<<<< HEAD
# NARD VVIP

NARD VVIP is a private, Studio-only developer test panel for experiences you own or are authorized to modify. It is not an executor script: the client refuses to start outside Roblox Studio, and the server independently checks Studio mode and an explicit UserId allowlist.

## Features

- Dark, draggable desktop-oriented interface with sidebar, hover states, settings search, minimize/close controls, notifications, and the `RightControl` visibility shortcut.
- NPC visualization for models tagged `NARDTestNPC`: occluded highlights, visible-target screen-space bounds, labels, health bars, category filtering, and range limits.
- Aim-training selection for living models tagged `NARDTrainingDummy`, with FOV selection, optional bounded camera assistance, hit/attempt accuracy, and reaction-time readouts. It does not target players or fire tools.
- NPC radar and a separate adjustable FOV circle.
- Studio-authorized flight, noclip, and capped walk-speed tests, enforced by the server.
- Per-user configuration saved through Roblox DataStoreService; movement enable states are intentionally not saved.

## Project layout

```text
NARD-VVIP/
├── src/
│   ├── main.client.lua
│   ├── UI.lua
│   ├── Theme.lua
│   ├── NPCESP.lua
│   ├── AimTrainer.lua
│   ├── Radar.lua
│   ├── FOV.lua
│   ├── Movement.lua
│   ├── Config.lua
│   ├── Notifications.lua
│   └── NARDServer.server.lua
├── README.md
└── INSTALLATION.md
```

See [INSTALLATION.md](./INSTALLATION.md) for Studio placement and the test checklist.

Run the optional integration/regression script at [tests/StudioRegression.client.lua](./tests/StudioRegression.client.lua) in an allowlisted Studio Play session as described in the installation guide.
=======
# NARD-VVIP
>>>>>>> 769f65699e895cb1772a16abf1fbd3fb9a0bf8fa
