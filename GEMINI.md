# Immortal Cultivation RPG — Master Rules & Architectural Memory

> [!IMPORTANT]
> **MANDATORY PRE-EXECUTION RULE VERIFICATION**:
> Before executing ANY script modification, UI update, instance creation, or code addition, you MUST cross-check your work against this rulebook. Never proceed with execution without verifying compliance with every applicable rule below.

---

## 1. Mandatory Pre-Execution Process Checklist

Before writing code or modifying instances:
1. [ ] **Hierarchy Check**: Will any script or localscript be nested under another script (`script.script`)? Must be strictly `0`.
2. [ ] **UI Origin Check**: Is any `ScreenGui` being created via `Instance.new("ScreenGui")` at runtime? Strictly prohibited; all UI must already exist in `StarterGui` in Edit Mode.
3. [ ] **UI Styling Preservation Check**: Are we preserving the user's manual layouts, fonts, gradients, sizes, and UIStrokes without wiping or overriding them?
4. [ ] **Emoji Check**: Does any `TextLabel.Text` or `TextButton.Text` contain unicode emojis? Strictly prohibited; use 2D image assets with `ImageLabel`/`ImageButton`.
5. [ ] **Enemy Rigging Check**: If creating/spawning enemies, is the clone positioned and parented FIRST before attaching accessories? Are accessories welded with invariant local welds (`C0 = localOffset, C1 = CFrame.new()`)? Is `SAMPLEENEMYMODEL` pristine?
6. [ ] **Overhead HUD Check**: For enemy BillboardGuis, is `AlwaysOnTop = false`, `LightInfluence = 0`, and `MaxDistance = 100`?
7. [ ] **Tool / Inventory Check**: Do tools have `CanBeDropped = false` and unique GUID tracking (`tool:SetAttribute(...)`)? Does hotbar compaction stay sequential?
8. [ ] **Physics / Combat Check**: Is knockback ground-clamped via raycast (`GetSurfaceY`) so entities never glitch into the sky?
9. [ ] **Language & Backpack**: Is all text/comments in English? Is the default CoreGui backpack disabled?
10. [ ] **Playtest Execution**: Are we ONLY playtesting when explicitly instructed/prompted by the user? Never initiate playtests autonomously.
11. [ ] **Server Execution Check**: Are we avoiding running `bridge/server.py`? Must NEVER run or start `bridge/server.py` here; the user runs it exclusively in their terminal.
12. [ ] **Rule Review Check**: Have you thoroughly reviewed all master rules before executing any code modification or making technical decisions?
13. [ ] **Luau & API Specs Check**: Have you verified the exact Luau & Roblox API specs (e.g. `TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)`, correct Enum items, signatures, and parameters) to prevent scripting errors?
14. [ ] **Mandatory Web Research Rule**: Before generating or modifying scripts in any programming language (Luau, Python, etc.), you MUST conduct web research / search docs for the specific language's latest API syntax, methods, and specifications to guarantee bug-free execution.

---

## 2. Artificial Parents & Script Hierarchy Rules (CRITICAL)

### The Core Rule:
- **No Artificial Script Parents (`script.script`)**: Scripts and LocalScripts must **never** be parented under another Script or LocalScript.
- Scripts must reside directly under their proper Roblox service containers:
  - Server scripts: `ServerScriptService` (or designated game service containers).
  - Client controller scripts: `StarterPlayer.StarterPlayerScripts` or directly within their respective `ScreenGui` in `StarterGui`.
  - Shared modules: `ReplicatedStorage`.
- **Never create artificial intermediate script containers** (e.g. `ServerScriptService.Server.Script` or `StarterPlayerScripts.Client.LocalScript`).

### Exceptions:
- **Physical Models**: Models that contain physical parts, meshes, accessories, welds, and attachments are natural assembly containers and allowed.
- **The `Ignore` Attribute**: Any parent or container instance with an attribute `Ignore == true` (`instance:GetAttribute("Ignore") == true`) is explicitly exempted.

### Edit Mode Rules:
- **Never modify `game.Players` in Edit Mode**: Do not inject or parent scripts, tools, or objects under `game.Players` or dummy player instances while Studio is in Edit Mode.

---

## 3. UI Design, Creation & Visual Asset Rules (STRICT)

### Pre-placed in `StarterGui` in Edit Mode (Zero Dynamic ScreenGui Creation):
- **Never use `Instance.new("ScreenGui")` at runtime.**
- **All UI components** (ScreenGuis, Frames, Buttons, Labels, ViewportFrames, Templates) must already be pre-placed into `StarterGui` in Edit Mode so the developer can visually inspect and tweak them directly in Roblox Studio.
- **Client Script Role**: Client scripts only locate existing instances replicated to `PlayerGui`, set initial visibility states (e.g., `overlay.Visible = false`), clone pre-placed templates, and bind events/animations.

### UI Styling Preservation:
- **Never wipe, reset, or override visual styling** crafted by the user (layouts, colors, gradients, UIStrokes, UICorners, backgrounds, and positions). Code must strictly bind functional logic to existing instances.

### Strict Prohibition of Unicode Emojis in Game UI:
- **Never use unicode emojis** (e.g., 🎲, 🔨, 🛡️, 📦, 👑, 👾, ⚔️, 🎒, 💥, ✓, ✕) inside `TextLabel.Text`, `TextButton.Text`, dialogs, combat HUDs, or billboards.
- **Always use dedicated 2D image assets** (`ImageLabel` or `ImageButton`) with thick black comic outlines, clean stylized colors, and transparent backgrounds.
- Upload image assets via the Open Cloud Asset Pipeline (`bridge/roblox_asset_uploader.py`) and use the resulting `rbxassetid://` IDs.

---

## 4. Enemy Rigging & Design Positioning Rules

When creating, equipping, or modifying custom enemy designs (armor, helmets, pauldrons, weapons, masks, accessories, particle effects, or visual attachments) using a template or sample rig (such as `SAMPLEENEMYMODEL` in Workspace):

1. **Never Attach Designs to or Relative to the Sample Model**:
   - `Workspace.SAMPLEENEMYMODEL` is strictly an archetypal rig template.
   - Never attach accessories, lights, or welds to `SAMPLEENEMYMODEL` directly.
   - Never calculate or construct accessory CFrames while the cloned enemy model is still situated at the sample rig's coordinates.

2. **Position and Parent the Cloned Rig FIRST**:
   - Always clone the sample rig into memory.
   - **Immediately pivot and place the cloned model at its actual target spawn CFrame** (`model:PivotTo(spawnCFrame)`) and parent it to its designated workspace container (e.g. `Workspace.BanditVillage`) **before** constructing or attaching any accessories.

3. **Attach Accessories Directly to the Positioned Enemy's Limbs with Invariant Welds**:
   ```luau
   local function attachAccessory(model: Model, bodyPart: BasePart, accessory: BasePart, localOffset: CFrame)
       accessory.CanCollide = false
       accessory.Massless = true
       accessory.CFrame = bodyPart.CFrame * localOffset
       accessory.Parent = model

       local weld = Instance.new("Weld")
       weld.Name = accessory.Name .. "Weld"
       weld.Part0 = bodyPart
       weld.Part1 = accessory
       weld.C0 = localOffset
       weld.C1 = CFrame.new()
       weld.Parent = accessory
   end
   ```
   - Always use `Weld` with `C0 = localOffset` and `C1 = CFrame.new()` so that the accessory's transform remains strictly invariant relative to the limb (Head, Torso, Right Arm) throughout animations, movement, and physics simulations.
   - Ensure `accessory.CanCollide = false` and `accessory.Massless = true` to avoid physics flinging or collision desynchronization.

4. **Preserve Template Rig Cleanliness**:
   - `Workspace.SAMPLEENEMYMODEL` must remain 100% clean and pristine (only base body parts, Humanoid, Animate, and BodyColors).

5. **Enemy Overhead HUD Specifications**:
   - All enemy overhead displays (`BillboardGui`, e.g. `OverheadHUD`) must have:
     - `AlwaysOnTop = false` (properly occluded by solid obstacles, walls, and terrain).
     - `LightInfluence = 0` (colors render with full vivid brightness unaffected by world lighting or shadows).
     - `MaxDistance = 100` (clean visuals without distant clutter).

---

## 5. Inventory Tools, Hotbar & Combat Physics Rules

### Unique ID Tracking (`ItemUniqueId` / `EggUniqueId`):
- When players own multiple identical tools, **never** search or destroy by generic tool name (`FindFirstChild("ToolName")`).
- Every tool created must be assigned a unique GUID identifier:
  ```luau
  tool:SetAttribute("ItemUniqueId", HttpService:GenerateGUID(false))
  ```
- Consume/destroy strictly by matching the unique identifier.

### Automatic Sequential Hotbar Compaction:
- When a tool is consumed from slot 1 or any slot, remaining tools in the hotbar must **automatically compact leftward** into sequential slots (`1..MAX_SLOTS`).
- Never allow dead slots, invisible gaps, or unmapped keybinds.

### Non-Droppable Tools:
- All tools must explicitly set:
  ```luau
  tool.CanBeDropped = false
  ```
  This prevents tools from being dropped into the void or lost on backspace/unequip.

### Combat Physics & Knockback:
- **Ground Clamping (No Glitching Y Height)**: When entities take knockback, their position must be raycast-clamped flush to the ground using `GetSurfaceY`. Entities must never launch uncontrollably into the sky.

---

## 6. General Project Architecture & Localization

- **Pure English**: All UI texts, prompts, notifications, dialogues, and code comments must strictly be in English.
- **CoreGui Backpack Disabled**: Keep the default Roblox CoreGui Backpack disabled (`SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)`) in favor of custom UI.
- **Roblox Studio Bridge Server**: Runs on `http://127.0.0.1:34875`. Status can be checked via:
  ```powershell
  Invoke-RestMethod http://127.0.0.1:34875/status
  ```
- **NEVER Run `bridge/server.py` Here**: Do NOT run, start, restart, or spawn `bridge/server.py` in this agent environment. The user will run and manage it strictly from their own terminal. Assume the server is already active on `http://127.0.0.1:34875`.
- **File Protection**: Never edit `src/remember.md` or this rules file unless explicitly instructed by the user.

---

## 7. Background Playtesting & Bug Investigation (Prompt-Only)

### STRICT RULE: ONLY Playtest When Explicitly Prompted by User:
- **Zero Autonomous Playtesting**: NEVER run playtests (`python bridge/visual_playtest.py`, `python bridge/playtest_suite.py`, or `bridge/ai_playtest_runner.py`) automatically, proactively, or as an unprompted follow-up after making changes.
- **Strictly On-Demand**: ONLY execute playtests when the user EXPLICITLY asks or prompts you to playtest.
- **Background & Non-Invasive**:
  - When explicitly prompted to playtest, the playtest system must operate 100% in the background via Studio's live bridge (`http://127.0.0.1:34875`).
  - Zero mouse cursor movement, zero window focus stealing, zero tab switching. Completely safe and silent while the user works in other tabs.
  - Automatically enables the red screen border, input denial lockout, and notification banner (`StarterGui.AITestingUI`) while tests run, and cleans them up upon completion.
- **Bug Discovery & Verification**:
  - Automatically query `LogService` to identify runtime console script errors.
  - Verify UI components, inventory, enemy counts, and module configurations.
  - Capture in-engine screenshots (`full`, `hotbar`, `hud`, etc.) and visually inspect them with `view_file` to detect visual bugs, misalignment, or broken textures.
  - Summarize results, list discovered bugs, and propose/apply concrete fixes immediately.


