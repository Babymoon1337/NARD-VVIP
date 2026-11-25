# Installation and test checklist

## Install in Roblox Studio

Use a private test copy of your experience. All modules are intended for Roblox Studio's supported client/server runtime; executor compatibility is not provided.

1. In `ReplicatedStorage`, create a `Folder` named `NARDVVIP`.
2. Copy `Theme.lua`, `UI.lua`, `Notifications.lua`, `NPCESP.lua`, `AimTrainer.lua`, `Radar.lua`, `FOV.lua`, `Movement.lua`, and `Config.lua` into that folder as `ModuleScript` instances. The instance names must match the file names without `.lua`.
3. Copy `main.client.lua` into `StarterPlayer > StarterPlayerScripts` as a `LocalScript`.
4. Copy `NARDServer.server.lua` into `ServerScriptService` as a `Script`.
5. In `NARDServer.server.lua`, add your Roblox numeric UserId to `AUTHORIZED_USER_IDS`. Leave the list restricted to trusted testers.
6. To test saved settings, publish the private test copy and enable **Game Settings > Security > Enable Studio Access to API Services** for that test experience. DataStore errors are reported in the interface. Do not enable Studio API access on a live experience just for this panel.
7. Start a Studio **Play** session. The server creates the remotes; unauthorized users and non-Studio clients are refused.

## Prepare test NPCs

- Add the `NARDTestNPC` CollectionService tag to NPC models that should appear in ESP/radar. Each needs a `Humanoid` and a `HumanoidRootPart` or `PrimaryPart`.
- Optionally set a string `NARDCategory` attribute such as `Hostile`, `Friendly`, or `Neutral` for ESP filtering.
- Add `NARDTrainingDummy` to training dummies that can be selected by the aim trainer. Give them a living `Humanoid` and preferably a `Head`.
- A model may carry both tags. Highlights use Roblox's occluded depth mode; ESP labels and bounds are shown only while the NPC root has a clear line of sight.

## Test checklist

- [ ] An allowlisted UserId sees the NARD VVIP panel in Studio Play; a non-allowlisted user and a non-Studio client do not.
- [ ] Drag, minimize, close, search, sidebar navigation, and `RightControl` work; closing removes overlays and restores movement defaults.
- [ ] ESP only shows tagged NPCs, respects walls and configured distance/category, and updates health/name/bounds toggles.
- [ ] Aim trainer selects only tagged training dummies; click hits/misses update accuracy and reaction time. Camera assistance remains off unless explicitly enabled.
- [ ] Radar range/size and FOV radius/transparency/color respond to settings.
- [ ] Flight responds to WASD/Space/LeftControl; noclip and walk speed are changed on the server. Reset restores normal movement.
- [ ] Save, reload, and reset configuration in a Studio session with DataStore API access enabled; confirm reported errors if API access is disabled.

## Regression test script

`tests/StudioRegression.client.lua` exercises the ESP overlay toggles, settings search and empty-section visibility, header spacing, camera replacement scaling, close cleanup after a callback error, and both client/server movement reset behavior.

1. Copy the `tests` folder's `StudioRegression.client.lua` to `StarterPlayer > StarterPlayerScripts` as a temporary `LocalScript`.
2. Add your test account UserId to `AUTHORIZED_USER_IDS` in the server script so the server movement reset test is authorized.
3. Start a Studio Play session. The script prints individual `[NARD regression PASS]` results to Output and raises an error if a check fails. The movement test briefly enables flight/noclip and resets them afterward.
4. Remove or disable the temporary test LocalScript after the run.

## Controls and limitations

- Flight: `W`/`A`/`S`/`D`, `Space` up, `LeftControl` down.
- `RightControl` hides/shows the main panel. Closing the panel destroys the active modules.
- Roblox DataStoreService is server-only and requires a published test experience plus Studio API access for Studio testing. Configuration is per UserId.
- The UI and movement tools deliberately operate only in Studio. This project has no Xeno/executor path, player ESP, universal aimbot, or public-server manipulation.
