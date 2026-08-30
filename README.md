# BWND_Bridge

A standalone compatibility layer that lets every `BWND_*` resource talk to the
server's framework, inventory, targeting and notification systems through **one
stable API** (`Bridge.*`) instead of a hand-rolled `framework/` folder per
resource.

Supported frameworks: **QBox (`qbx_core`)**, **QBCore (`qb-core`)**, **ESX
(`es_extended`)**.
Everything else (inventory / target / notify / vehicle props / society banking) is
auto-detected from whatever is running. Also can add your own logic

---

## Install

1. Drop `BWND_Bridge` into your resources (anywhere; the category folder
   `[IGNITE]/[BWND]` is fine).
2. `ensure BWND_Bridge` **before** any `BWND_*` resource and **after** your
   framework + `ox_lib`.
3. (Optional) open `config.lua` and pin anything auto-detection gets wrong.

`ox_lib` is required.

---

## Using it from another resource

Add **one line** to the consumer's `fxmanifest.lua` and declare the dependency:

```lua
shared_script '@ox_lib/init.lua'      -- if the resource uses ox_lib, keep this first
shared_script '@BWND_Bridge/init.lua'

dependency 'BWND_Bridge'
```

`init.lua` loads the bridge implementation directly into that resource's Lua
state, so `Bridge.*` calls are plain function calls — callbacks (targets, usable
items, progress bars) and by-reference tables just work. No per-call export cost.

If that in-state load can't run (some CfxLua builds sandbox it), `init.lua`
transparently falls back to routing every `Bridge.*` through
`exports.BWND_Bridge:*`. In that mode the data API is identical, but helpers that
take a Lua callback (`RegisterUsableItem`, the target `Add*` helpers with
`onSelect`) and `GetPlayer`/`GetPlayerByCitizenId` (which return a live framework
object) are degraded — use the source-based data helpers (`GetJob(src)`,
`GetPlayerName(src)`, `GetIdentifier(src)`, …) which work in both modes.

Then, anywhere in that resource:

```lua
-- SERVER
RegisterNetEvent('myshop:buy', function(price)
    local src = source
    if Bridge.RemoveMoney(src, 'bank', price, 'myshop-purchase') then
        Bridge.AddItem(src, 'sandwich', 1)
        Bridge.Notify(src, 'Enjoy your sandwich', 'success')
    end
end)

Bridge.OnPlayerLoaded(function(src, data)
    print(('%s (%s) loaded as %s'):format(data.name, data.citizenid, data.job.name))
end)

-- CLIENT
if Bridge.GetJob().name == 'police' and Bridge.GetJob().onduty then
    Bridge.ShowTextUI('[E] Open armoury')
end
```

### Third-party / non-Lua resources

Every server and client function is also a real export:

```lua
local money = exports.BWND_Bridge:GetMoney(src, 'cash')
```

Exports cannot carry Lua callbacks, so `RegisterUsableItem`, the `AddTarget*`
helpers and `ProgressBar` are only useful through `@BWND_Bridge/init.lua`.

---

## Config (`config.lua`)

| Key            | Default  | Notes |
|----------------|----------|-------|
| `Framework`    | `auto`   | `qbx` / `qb` / `esx` |
| `Inventory`    | `auto`   | detection order: `jaksam_inventory` → `ox_inventory` → `qb-inventory` → framework-native. jaksam is used natively rather than through its lossy ox-compat shim. |
| `Target`       | `auto`   | detection order: `core_focus` → `ox_target` → `qb-target`. core_focus is called natively, not through its ox_target/qb-target emulation. |
| `Notify`       | `auto`   | `ox_lib` when running, else the framework |
| `TextUI`       | `auto`   | `ox_lib` when running, else the framework |
| `VehicleProps` | `auto`   | `jg-mechanic` when running, else `ox_lib` |
| `Society`      | `auto`   | `qb-banking` / `Renewed-Banking` / `qb-management` / `esx_society` |
| `BlackMoneyAccount` | `black_money` | ESX account name mapped to the `'black'` money type |
| `Debug`        | `false`  | print detection + warnings |


Detected values are printed once on start:

```
[BWND_Bridge] server | framework=qbx inventory=ox_inventory target=ox_target notify=ox_lib vehProps=jg-mechanic
```

---

## API — server

Identifiers: every `id` argument accepts a **server id** or a **citizenid**
(qbx/qb) / **identifier** (esx).

### Player
| Function | Returns |
|---|---|
| `Bridge.GetPlayer(id)` | raw framework player object |
| `Bridge.GetPlayerByCitizenId(cid)` | raw object |
| `Bridge.GetPlayerByIdentifier(ident)` | raw object |
| `Bridge.GetSource(playerOrId)` | number |
| `Bridge.GetIdentifier(id)` / `GetCitizenId(id)` | citizenid (qb) / identifier (esx) |
| `Bridge.GetLicense(id, kind?)` | `license:xxxx` (`kind` = `license`/`discord`/`steam`…) |
| `Bridge.GetPlayerName(id)` | `"First Last"` |
| `Bridge.GetPlayers()` | array of loaded server ids |
| `Bridge.IsPlayerLoaded(id)` | boolean |
| `Bridge.GetPlayerData(id)` | normalised snapshot ↓ |

```lua
{ source, citizenid, identifier, name, firstname, lastname,
  job = <normalised job>, gang = <normalised gang|nil>,
  money = { cash, bank, black }, metadata, charinfo }
```

### Money — types: `'cash'`, `'bank'`, `'black'` (others pass through, e.g. `'crypto'`)
| Function | Returns |
|---|---|
| `Bridge.GetMoney(id, type)` | number |
| `Bridge.AddMoney(id, type, amount, reason?)` | boolean |
| `Bridge.RemoveMoney(id, type, amount, reason?)` | boolean (false if short) |
| `Bridge.SetMoney(id, type, amount, reason?)` | boolean |
| `Bridge.CanAfford(id, type, amount)` | boolean |
| `Bridge.ChargePlayer(id, amount, reason?, order?)` | `ok, account` — tries `{'cash','bank'}` by default |

`'black'` is unsupported on qbx/qb and returns `0` / `false`.

### Jobs & gangs — normalised shape
```lua
{ name, label, type, salary, onduty, isboss,
  grade = { name, level, isboss } }
```
| Function | Returns |
|---|---|
| `Bridge.GetJob(id)` | job \| nil |
| `Bridge.GetGang(id)` | gang \| nil (always nil on ESX) |
| `Bridge.GetJobGrade(jobOrId)` | number |
| `Bridge.SetJob(id, name, grade)` | boolean |
| `Bridge.SetGang(id, name, grade)` | boolean (false on ESX) |
| `Bridge.SetJobDuty(id, bool)` | boolean |
| `Bridge.IsOnDuty(id)` | boolean |
| `Bridge.GetJobs()` / `Bridge.GetGangs()` | raw framework definition tables |
| `Bridge.GetGroupGrades('job'\|'gang', name)` | sorted `{ {level,name,isboss}, … }` |
| `Bridge.CountPlayersWithJob(name, onDutyOnly?)` | number |

### Inventory — `jaksam_inventory` (native) → `ox_inventory` → `qb-inventory` → framework-native
| Function | Returns |
|---|---|
| `Bridge.GetItemCount(id, item, metadata?)` | number |
| `Bridge.HasItem(id, item, count?)` | boolean |
| `Bridge.AddItem(id, item, count?, metadata?, slot?)` | boolean |
| `Bridge.RemoveItem(id, item, count?, metadata?, slot?)` | boolean |
| `Bridge.CanCarryItem(id, item, count?)` | boolean (real check on jaksam/ox only) |
| `Bridge.GetItem(id, item, metadata?)` | slot/item data \| nil |
| `Bridge.GetInventory(id)` | inventory payload |
| `Bridge.GetItemLabel(item)` | string |
| `Bridge.SetItemMetadata(id, slot, metadata)` | boolean (jaksam/ox only) |
| `Bridge.RegisterUsableItem(item, cb)` | — `cb(src, item)`; on jaksam uses its native `registerUsableItem`, else the framework |

### Permissions
qbx / qb / esx all deprecated their permission-level APIs to `IsPlayerAceAllowed`,
so the bridge is ACE-only:

- `Bridge.HasPermission(src, perm)` — `perm` string or array (any-of). Checks the
  ACE `perm` and `group.<perm>` (skips the `group.` variant when `perm` contains a
  `.`, e.g. `command.gcreate`). Also matches an ESX group string.
- `Bridge.GetPlayerGroup(src)` — ESX group string; `nil` on qbx/qb.

e.g. `Bridge.HasPermission(src, 'admin')`, `Bridge.HasPermission(src, 'god')`.

### Society banking (best-effort)
`Bridge.GetSocietyMoney(name)` · `Bridge.AddSocietyMoney(name, amount)` ·
`Bridge.RemoveSocietyMoney(name, amount)` — all no-op / `0` when `Society = 'none'`.

### UI
`Bridge.Notify(src, msg, type?, duration?)` ·
`Bridge.ShowTextUI(src, msg, opts?)` · `Bridge.HideTextUI(src)`

---

## API — client

| Area | Functions |
|---|---|
| Player | `GetPlayerData()`, `IsLoggedIn()`, `GetJob()`, `GetGang()`, `GetIdentifier()` / `GetCitizenId()`, `GetPlayerName()` |
| Inventory | `GetItemCount(item)`, `HasItem(item, count?)` |
| Vehicle | `GetVehicleProperties(veh)`, `SetVehicleProperties(veh, props)` — jg-mechanic aware |
| UI | `Notify(msg, type?, dur?)`, `ShowTextUI(msg, opts?)`, `HideTextUI()`, `IsTextUIOpen()`, `ProgressBar(opts)` → bool, `SkillCheck(difficulty, inputs)` → bool |
| Target | `AddTargetModel(models, options)`, `AddTargetEntity(entity, options)`, `AddBoxZone(name, coords, size, options, zoneOpts?)`, `RemoveZone(id)`, `RemoveTargetModel(models, labels?)`, `RemoveTargetEntity(entity, labels?)`, `SetTargetingEnabled(state)` |
| Escape hatch | `GetCoreObject()` |

`options` for the target helpers always use the **ox_target** shape
(`{ name, label, icon, distance, groups, items, canInteract, onSelect, event, serverEvent, type }`).
For core_focus / qb-target they are translated to the native (`action` / `job` /
`item`) shape, and `onSelect(data)` is wrapped so your callback still receives a
single `{ entity, coords, distance, ... }` table regardless of backend.

---

## Normalised lifecycle events

`server/events.lua` and `client/events.lua` translate every framework's native
events into one set. Subscribe with the sugar from `init.lua`:

| Sugar | Server callback | Client callback |
|---|---|---|
| `Bridge.OnPlayerLoaded(cb)` | `cb(src, playerData)` | `cb()` |
| `Bridge.OnPlayerUnloaded(cb)` | `cb(src)` | `cb()` |
| `Bridge.OnPlayerDropped(cb)` | `cb(src, reason)` | — |
| `Bridge.OnJobUpdate(cb)` | `cb(src, job)` | `cb(job)` |
| `Bridge.OnGangUpdate(cb)` | `cb(src, gang)` | `cb(gang)` |
| `Bridge.OnDutyUpdate(cb)` | `cb(src, onDuty, job)` | `cb(onDuty, job)` |

Or listen to the raw events directly: `BWND_Bridge:server:playerLoaded`,
`BWND_Bridge:client:jobUpdate`, etc.

---

## Hooks & events (`Bridge.Hooks`)

A shared hook/event engine (`shared/hooks.lua`). A resource that wants **other**
resources to hook into it opts in; the owner fires its chain with a local
`Bridge.Hooks.Run(...)`.

### Opting a resource in (the owner)

```lua
-- fxmanifest.lua  (after '@BWND_Bridge/init.lua')
shared_script '@BWND_Bridge/shared/hooks.lua'
```
```lua
-- server/hooks.lua  and/or  client/hooks.lua
Bridge.ExposeHooks()
```

Publishes, on that resource:

| Export | |
|---|---|
| `exports.<owner>:RegisterHook(name[, exportName])` | → `id`. With `exportName`: an export on the caller. Without: dispatch mode (used by `Bridge.Hooks.Register`) |
| `exports.<owner>:RemoveHook(id)` | → boolean |
| `exports.<owner>:RunHook(name, payload)` | → `ok, reason, payload` |
| `exports.<owner>:Emit(name, payload)` | fire-and-forget → `<owner>:<name>` + `<owner>:any` |

A resource's hooks are dropped automatically when it stops.

### Firing (inside the owning resource)

```lua
local ok, reason, payload = Bridge.Hooks.Run('beforeVehicleSpawn', { src = source, plate = plate })
if not ok then return { ok = false, reason = reason } end   -- payload may have been filtered
...
Bridge.Hooks.Emit('vehicleSpawned', { src = source, plate = plate })
```

### Hook return contract

The registered export is called `fn(payload)`; its return:

| return | effect |
|---|---|
| `nil` / `true` | allow, no change |
| `false` | veto |
| `{ allow = false, reason = '…' }` | veto with a reason |
| `{ …other keys… }` | allow; keys shallow-merge into `payload` (filter) |

Every call is `pcall`-wrapped; an errored hook is logged and treated as *allow*.
A name with zero hooks returns *allow* instantly. Registration order only.

### Consuming — option A: inline closure

Add to your fxmanifest: `shared_script '@BWND_Bridge/shared/hooks.lua'`. Your
closure stays in your own state — a string-only dispatch export is created for you.

```lua
CreateThread(function()
    while GetResourceState('BWND_Garages') ~= 'started' do Wait(200) end

    Bridge.Hooks.Register('BWND_Garages', 'beforeVehicleSpawn', function(data)
        if CasinoDebtors[data.src] then
            return { allow = false, reason = 'Settle your casino debt first.' }
        end
    end)
end)
```

### Consuming — option B: named export (no `@`-include)

```lua
-- 1. the hook body as an export on YOUR resource
exports('onGarageSpawn', function(data)
    if CasinoDebtors[data.src] then
        return { allow = false, reason = 'Settle your casino debt first.' }
    end
end)

-- 2. register it by name (wait for the owner to be up)
CreateThread(function()
    while GetResourceState('BWND_Garages') ~= 'started' do Wait(200) end
    exports.BWND_Garages:RegisterHook('beforeVehicleSpawn', 'onGarageSpawn')
end)

-- events: plain AddEventHandler on '<owner>:<name>'
AddEventHandler('BWND_Garages:vehicleStored', function(data)
    print(('%s stored %s'):format(data.src, data.plate))
end)
```