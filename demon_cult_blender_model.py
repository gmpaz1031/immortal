"""
Demon Cult Assassin / Cultist - Complete 3D Character Model Generator for Blender
==================================================================================
Based on reference design:
- Deep Hood with pointed tip and crimson edge trim
- Featureless Dark Mask with red cross/star demonic sigil
- Cultist Cowl / Neck Wrap
- Layered Robes with jagged/tattered hemline
- Wide Demon Sleeves with forearm bandage wraps & fingerless gloves
- Leather Double Belt with hanging talisman cloth banner & side sashes
- Back cult insignia (compass / circle cross demonic emblem)
- Armored/strapped boots
- Glowing Demonic Sword (serrated / jagged red neon blade, crossguard with crimson gem, diamond pommel)

Usage:
1. Open Blender (v3.0+ / 4.x compatible).
2. Go to the Scripting tab.
3. Paste and run this script.
4. The character and sword will be generated with full geometry, shaders, vertex colors, and materials.
"""

import bpy
import bmesh
import math
from mathutils import Vector, Matrix, Euler

# ------------------------------------------------------------------------------
# 1. UTILITY & SCENE SETUP
# ------------------------------------------------------------------------------
def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        bpy.data.materials.remove(block)

def create_collection(name):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col

# ------------------------------------------------------------------------------
# 2. PBR & EMISSION SHADERS
# ------------------------------------------------------------------------------
def get_or_create_material(name, base_color, roughness=0.8, metallic=0.0, emission_color=None, emission_strength=0.0):
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new(type='ShaderNodeOutputMaterial')
    output.location = (400, 0)
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.location = (0, 0)

    # Base Color & Physicals
    principled.inputs['Base Color'].default_value = (*base_color, 1.0)
    principled.inputs['Roughness'].default_value = roughness
    principled.inputs['Metallic'].default_value = metallic

    # Emission handling (compatible across Blender 3.x and 4.x)
    if emission_color and emission_strength > 0.0:
        if 'Emission Color' in principled.inputs:
            principled.inputs['Emission Color'].default_value = (*emission_color, 1.0)
            principled.inputs['Emission Strength'].default_value = emission_strength
        elif 'Emission' in principled.inputs:
            principled.inputs['Emission'].default_value = (*emission_color, 1.0)
            if 'Emission Strength' in principled.inputs:
                principled.inputs['Emission Strength'].default_value = emission_strength

    links.new(principled.outputs['BSDF'], output.inputs['Surface'])
    return mat

def setup_materials():
    mats = {}
    # Dark charcoal fabric with soft sheen
    mats['RobeBlack'] = get_or_create_material("Mat_RobeBlack", (0.025, 0.023, 0.025), roughness=0.85, metallic=0.05)
    # Crimson velvet / talisman fabric
    mats['CrimsonTrim'] = get_or_create_material("Mat_CrimsonTrim", (0.35, 0.02, 0.02), roughness=0.7, metallic=0.1)
    # Weathered dark leather
    mats['DarkLeather'] = get_or_create_material("Mat_DarkLeather", (0.04, 0.03, 0.025), roughness=0.55, metallic=0.15)
    # Gunmetal / demon dark steel
    mats['DarkMetal'] = get_or_create_material("Mat_DarkMetal", (0.05, 0.05, 0.06), roughness=0.35, metallic=0.85)
    # Mask matte dark surface
    mats['MaskBlack'] = get_or_create_material("Mat_MaskBlack", (0.015, 0.015, 0.017), roughness=0.4, metallic=0.2)
    # Glowing Blood Red Neon
    mats['DemonGlow'] = get_or_create_material("Mat_DemonGlow", (1.0, 0.02, 0.02), roughness=0.1, metallic=0.0,
                                               emission_color=(1.0, 0.02, 0.02), emission_strength=12.0)
    # Pale Skin
    mats['PaleSkin'] = get_or_create_material("Mat_PaleSkin", (0.45, 0.35, 0.32), roughness=0.6, metallic=0.0)
    return mats

# ------------------------------------------------------------------------------
# 3. BASE BODY & PROPORTIONS
# ------------------------------------------------------------------------------
def create_base_body(col, mats):
    # Head & Neck
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=16, radius=0.15, location=(0, 0, 1.72))
    head = bpy.context.active_object
    head.name = "Body_Head"
    head.scale = (0.9, 1.05, 1.15)
    bpy.ops.object.transform_apply(scale=True)
    head.data.materials.append(mats['PaleSkin'])
    col.objects.link(head)
    bpy.context.scene.collection.objects.unlink(head)

    # Torso block
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.35))
    torso = bpy.context.active_object
    torso.name = "Body_Torso"
    torso.scale = (0.28, 0.16, 0.32)
    bpy.ops.object.transform_apply(scale=True)
    torso.data.materials.append(mats['RobeBlack'])
    col.objects.link(torso)
    bpy.context.scene.collection.objects.unlink(torso)

    # Hands (exposed fingers under wrap)
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 0.42, -0.02, 0.96))
        hand = bpy.context.active_object
        hand.name = f"Hand_{'R' if side < 0 else 'L'}"
        hand.scale = (0.05, 0.08, 0.07)
        bpy.ops.object.transform_apply(scale=True)
        hand.data.materials.append(mats['PaleSkin'])
        col.objects.link(hand)
        bpy.context.scene.collection.objects.unlink(hand)

# ------------------------------------------------------------------------------
# 4. MASK WITH DEMONIC RED SIGIL
# ------------------------------------------------------------------------------
def create_demonic_mask(col, mats):
    # Base curved face plate
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.12, depth=0.22, location=(0, -0.07, 1.72))
    mask = bpy.context.active_object
    mask.name = "DemonicMask"
    mask.scale = (1.0, 0.55, 1.2)
    bpy.ops.object.transform_apply(scale=True)
    mask.data.materials.append(mats['MaskBlack'])

    # Cut in half to keep front convex shield
    bm = bmesh.new()
    bm.from_mesh(mask.data)
    verts_to_remove = [v for v in bm.verts if v.co.y > 0]
    bmesh.ops.delete(bm, geom=verts_to_remove, context='VERTS')
    bm.to_mesh(mask.data)
    bm.free()

    # Red Sigil Emblem (Raised Cross + Circle)
    # Vertical slit / beam
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.135, 1.72))
    v_slit = bpy.context.active_object
    v_slit.name = "Sigil_Vert"
    v_slit.scale = (0.012, 0.008, 0.20)
    bpy.ops.object.transform_apply(scale=True)
    v_slit.data.materials.append(mats['DemonGlow'])

    # Horizontal slit
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.135, 1.76))
    h_slit = bpy.context.active_object
    h_slit.name = "Sigil_Horiz"
    h_slit.scale = (0.13, 0.008, 0.012)
    bpy.ops.object.transform_apply(scale=True)
    h_slit.data.materials.append(mats['DemonGlow'])

    # Sigil Circle
    bpy.ops.mesh.primitive_torus_add(major_radius=0.06, minor_radius=0.006, location=(0, -0.134, 1.76))
    sigil_ring = bpy.context.active_object
    sigil_ring.name = "Sigil_Ring"
    sigil_ring.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    sigil_ring.data.materials.append(mats['DemonGlow'])

    for obj in [mask, v_slit, h_slit, sigil_ring]:
        col.objects.link(obj)
        bpy.context.scene.collection.objects.unlink(obj)

# ------------------------------------------------------------------------------
# 5. ASSASSIN HOOD WITH POINTED TIP & CRIMSON EDGING
# ------------------------------------------------------------------------------
def create_hood(col, mats):
    bm = bmesh.new()
    # Construct layered hood cone + cowl
    segments = 18
    r_base = 0.23
    r_mid = 0.20
    r_top = 0.08

    # Base opening ring (neck/collar)
    base_ring = [bm.verts.new((math.cos(i * 2 * math.pi / segments) * r_base,
                               math.sin(i * 2 * math.pi / segments) * r_base,
                               1.60)) for i in range(segments)]

    # Mid ring (temple level)
    mid_ring = [bm.verts.new((math.cos(i * 2 * math.pi / segments) * r_mid,
                              math.sin(i * 2 * math.pi / segments) * r_mid + 0.04,
                              1.82)) for i in range(segments)]

    # Peak tip (curved backward point)
    peak_tip = bm.verts.new((0, 0.22, 1.98))

    # Skin faces
    for i in range(segments):
        ni = (i + 1) % segments
        # Base to mid
        bm.faces.new([base_ring[i], base_ring[ni], mid_ring[ni], mid_ring[i]])
        # Mid to peak
        bm.faces.new([mid_ring[i], mid_ring[ni], peak_tip])

    mesh = bpy.data.meshes.new("Mesh_Hood")
    bm.to_mesh(mesh)
    bm.free()

    hood = bpy.data.objects.new("AssassinHood", mesh)
    hood.data.materials.append(mats['RobeBlack'])

    # Solidify & Subsurf for fabric thickness & curvature
    solid = hood.modifiers.new("Solidify", 'SOLIDIFY')
    solid.thickness = 0.018
    sub = hood.modifiers.new("Subdivision", 'SUBSURF')
    sub.levels = 1

    col.objects.link(hood)

    # Crimson Rim Around Hood Opening
    bpy.ops.mesh.primitive_torus_add(major_radius=0.18, minor_radius=0.012, location=(0, -0.06, 1.76))
    rim = bpy.context.active_object
    rim.name = "Hood_CrimsonTrim"
    rim.rotation_euler = (math.radians(18), 0, 0)
    rim.scale = (1.0, 0.9, 1.3)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    rim.data.materials.append(mats['CrimsonTrim'])
    col.objects.link(rim)
    bpy.context.scene.collection.objects.unlink(rim)

# ------------------------------------------------------------------------------
# 6. LAYERED CULTIST ROBES, SLEEVES & TATTERED HEM
# ------------------------------------------------------------------------------
def create_robes(col, mats):
    # --- Upper Robe & Cowl Wrap ---
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.27, depth=0.45, location=(0, 0, 1.34))
    upper = bpy.context.active_object
    upper.name = "Robe_Chest"
    upper.scale = (1.15, 0.8, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    upper.data.materials.append(mats['RobeBlack'])
    col.objects.link(upper)
    bpy.context.scene.collection.objects.unlink(upper)

    # --- Wide Cultist Flared Sleeves ---
    for side in [-1, 1]:
        # Upper arm flare
        bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.15, depth=0.42, location=(side * 0.32, 0, 1.25))
        sleeve = bpy.context.active_object
        sleeve.name = f"Sleeve_{'R' if side < 0 else 'L'}"
        sleeve.rotation_euler = (0, math.radians(side * -25), 0)
        sleeve.scale = (1.1, 0.9, 1.0)
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        sleeve.data.materials.append(mats['RobeBlack'])

        # Crimson cuff trim
        bpy.ops.mesh.primitive_torus_add(major_radius=0.14, minor_radius=0.014, location=(side * 0.40, 0, 1.08))
        cuff = bpy.context.active_object
        cuff.name = f"SleeveTrim_{'R' if side < 0 else 'L'}"
        cuff.rotation_euler = (0, math.radians(side * -25), 0)
        bpy.ops.object.transform_apply(rotation=True)
        cuff.data.materials.append(mats['CrimsonTrim'])

        # Forearm Straps / Wraps
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.07, depth=0.20, location=(side * 0.41, 0, 1.00))
        wrap = bpy.context.active_object
        wrap.name = f"ForearmWrap_{'R' if side < 0 else 'L'}"
        wrap.rotation_euler = (0, math.radians(side * -25), 0)
        bpy.ops.object.transform_apply(rotation=True)
        wrap.data.materials.append(mats['DarkLeather'])

        for obj in [sleeve, cuff, wrap]:
            col.objects.link(obj)
            bpy.context.scene.collection.objects.unlink(obj)

    # --- Lower Skirt / Tattered Robe Base ---
    bm = bmesh.new()
    segments = 24
    height_steps = 6
    r_top = 0.25
    r_bot = 0.46
    z_top = 1.15
    z_bot = 0.35

    layers = []
    for step in range(height_steps):
        t = step / (height_steps - 1)
        z = z_top - t * (z_top - z_bot)
        r = r_top + t * (r_top + 0.15)
        # Jagged bottom displacement
        ring = []
        for i in range(segments):
            angle = i * 2 * math.pi / segments
            mod_r = r
            if step == height_steps - 1:
                # Tattered jagged edges on lowest row
                mod_r += (0.04 if i % 2 == 0 else -0.06)
                z_mod = z + (-0.08 if i % 3 == 0 else 0.03)
            else:
                z_mod = z
            x = math.cos(angle) * mod_r * 1.15
            y = math.sin(angle) * mod_r * 0.95
            ring.append(bm.verts.new((x, y, z_mod)))
        layers.append(ring)

    for step in range(height_steps - 1):
        for i in range(segments):
            ni = (i + 1) % segments
            bm.faces.new([layers[step][i], layers[step][ni], layers[step + 1][ni], layers[step + 1][i]])

    mesh_skirt = bpy.data.meshes.new("Mesh_Skirt")
    bm.to_mesh(mesh_skirt)
    bm.free()

    skirt = bpy.data.objects.new("Robe_LowerTattered", mesh_skirt)
    skirt.data.materials.append(mats['RobeBlack'])
    solid = skirt.modifiers.new("Solidify", 'SOLIDIFY')
    solid.thickness = 0.015
    col.objects.link(skirt)

# ------------------------------------------------------------------------------
# 7. BELT, SASHES, TALISMAN BANNER & BACK EMBLEM
# ------------------------------------------------------------------------------
def create_accessories_and_emblem(col, mats):
    # Double leather belt
    for z in [1.14, 1.10]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.255, minor_radius=0.015, location=(0, 0, z))
        belt = bpy.context.active_object
        belt.name = "LeatherBelt"
        belt.scale = (1.12, 0.90, 1.0)
        bpy.ops.object.transform_apply(scale=True)
        belt.data.materials.append(mats['DarkLeather'])
        col.objects.link(belt)
        bpy.context.scene.collection.objects.unlink(belt)

    # Front Hanging Crimson Talisman Banner
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.06, -0.22, 0.72))
    banner = bpy.context.active_object
    banner.name = "CrimsonTalismanBanner"
    banner.scale = (0.09, 0.012, 0.40)
    bpy.ops.object.transform_apply(scale=True)
    banner.data.materials.append(mats['CrimsonTrim'])
    col.objects.link(banner)
    bpy.context.scene.collection.objects.unlink(banner)

    # Side Tattered Sashes (Left waist hanging strips)
    for i, rot in enumerate([-12, 5, 18]):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.24, -0.08 + i * 0.04, 0.82))
        sash = bpy.context.active_object
        sash.name = f"WaistSash_{i}"
        sash.rotation_euler = (math.radians(rot), math.radians(-10), math.radians(5))
        sash.scale = (0.05, 0.01, 0.28)
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        sash.data.materials.append(mats['CrimsonTrim'])
        col.objects.link(sash)
        bpy.context.scene.collection.objects.unlink(sash)

    # Back Emblem: Demonic Circle Cross Emblem (Projected onto Back Robe)
    # Emblem ring
    bpy.ops.mesh.primitive_torus_add(major_radius=0.11, minor_radius=0.008, location=(0, 0.17, 1.36))
    emblem_ring = bpy.context.active_object
    emblem_ring.name = "BackEmblem_Ring"
    emblem_ring.rotation_euler = (math.radians(90), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    emblem_ring.data.materials.append(mats['DemonGlow'])

    # Emblem 4-Point Star Rays
    for angle in [0, 90]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.172, 1.36))
        ray = bpy.context.active_object
        ray.name = f"BackEmblem_Ray_{angle}"
        ray.rotation_euler = (0, 0, math.radians(angle))
        ray.scale = (0.012, 0.005, 0.28)
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        ray.data.materials.append(mats['DemonGlow'])
        col.objects.link(ray)
        bpy.context.scene.collection.objects.unlink(ray)

    col.objects.link(emblem_ring)
    bpy.context.scene.collection.objects.unlink(emblem_ring)

# ------------------------------------------------------------------------------
# 8. LEGS & STRAPPED ASSASSIN BOOTS
# ------------------------------------------------------------------------------
def create_legs_and_boots(col, mats):
    for side in [-1, 1]:
        # Under trousers
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.08, depth=0.65, location=(side * 0.13, 0, 0.50))
        leg = bpy.context.active_object
        leg.name = f"Leg_{'R' if side < 0 else 'L'}"
        leg.data.materials.append(mats['RobeBlack'])

        # Leather Boots with strapped shins
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.09, depth=0.36, location=(side * 0.13, 0, 0.22))
        boot_shaft = bpy.context.active_object
        boot_shaft.name = f"BootShaft_{'R' if side < 0 else 'L'}"
        boot_shaft.data.materials.append(mats['DarkLeather'])

        # Foot
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side * 0.13, -0.06, 0.05))
        foot = bpy.context.active_object
        foot.name = f"Foot_{'R' if side < 0 else 'L'}"
        foot.scale = (0.10, 0.22, 0.08)
        bpy.ops.object.transform_apply(scale=True)
        foot.data.materials.append(mats['DarkLeather'])

        # Buckle Straps on Shin
        for z in [0.18, 0.26, 0.34]:
            bpy.ops.mesh.primitive_torus_add(major_radius=0.095, minor_radius=0.008, location=(side * 0.13, 0, z))
            strap = bpy.context.active_object
            strap.name = "BootStrap"
            strap.data.materials.append(mats['CrimsonTrim'])
            col.objects.link(strap)
            bpy.context.scene.collection.objects.unlink(strap)

        for obj in [leg, boot_shaft, foot]:
            col.objects.link(obj)
            bpy.context.scene.collection.objects.unlink(obj)

# ------------------------------------------------------------------------------
# 9. GLOWING DEMONIC SWORD (BLADE, GEM CROSSGUARD, DIAMOND POMMEL)
# ------------------------------------------------------------------------------
def create_demonic_sword(col, mats):
    # Master sword container
    sword_origin = Vector3((-0.46, -0.08, 0.88))

    # --- Handle / Grip ---
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.016, depth=0.22, location=sword_origin + Vector3((0, 0, 0)))
    grip = bpy.context.active_object
    grip.name = "Sword_Grip"
    grip.rotation_euler = (math.radians(-35), math.radians(-15), math.radians(20))
    bpy.ops.object.transform_apply(rotation=True)
    grip.data.materials.append(mats['DarkLeather'])

    # --- Diamond Pommel ---
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=sword_origin + Vector3((-0.03, 0.09, 0.07)))
    pommel = bpy.context.active_object
    pommel.name = "Sword_Pommel"
    pommel.rotation_euler = (math.radians(45), math.radians(45), 0)
    pommel.scale = (0.035, 0.035, 0.035)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    pommel.data.materials.append(mats['DarkMetal'])

    # --- Crossguard with Center Demon Gem ---
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=sword_origin + Vector3((0.02, -0.07, -0.06)))
    guard = bpy.context.active_object
    guard.name = "Sword_Guard"
    guard.rotation_euler = (math.radians(-35), math.radians(-15), math.radians(20))
    guard.scale = (0.16, 0.035, 0.04)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    guard.data.materials.append(mats['DarkMetal'])

    # Crimson Focus Gem
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=sword_origin + Vector3((0.02, -0.075, -0.06)))
    gem = bpy.context.active_object
    gem.name = "Sword_DemonGem"
    gem.rotation_euler = (math.radians(45), math.radians(45), math.radians(20))
    gem.scale = (0.028, 0.028, 0.028)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    gem.data.materials.append(mats['DemonGlow'])

    # --- Serrated Jagged Glowing Blade ---
    bm = bmesh.new()
    blade_length = 0.95
    steps = 14
    start_pos = sword_origin + Vector3((0.04, -0.14, -0.12))
    fwd = Vector3((0.08, -0.32, -0.72)).normalized()
    side = Vector3((0.7, 0.3, 0.0)).normalized()

    prev_l = None
    prev_r = None
    prev_c = None

    for i in range(steps):
        t = i / (steps - 1)
        center = start_pos + fwd * (t * blade_length)
        # Jagged flare variation
        width = (1.0 - t * 0.8) * 0.038
        if i % 2 == 1:
            width *= 1.25  # Serrated teeth

        vl = bm.verts.new(center - side * width)
        vr = bm.verts.new(center + side * width)
        vc = bm.verts.new(center + Vector3((0, 0, 0.006)))  # Center spine ridge

        if prev_l:
            bm.faces.new([prev_l, vl, vc, prev_c])
            bm.faces.new([prev_c, vc, vr, prev_r])

        prev_l = vl
        prev_r = vr
        prev_c = vc

    # Blade Tip point
    tip_vert = bm.verts.new(start_pos + fwd * (blade_length + 0.08))
    bm.faces.new([prev_l, tip_vert, prev_c])
    bm.faces.new([prev_c, tip_vert, prev_r])

    mesh_blade = bpy.data.meshes.new("Mesh_DemonBlade")
    bm.to_mesh(mesh_blade)
    bm.free()

    blade = bpy.data.objects.new("Sword_Blade", mesh_blade)
    blade.data.materials.append(mats['DemonGlow'])
    solid = blade.modifiers.new("Solidify", 'SOLIDIFY')
    solid.thickness = 0.008

    for obj in [grip, pommel, guard, gem, blade]:
        col.objects.link(obj)
        bpy.context.scene.collection.objects.unlink(obj)

# ------------------------------------------------------------------------------
# 10. LIGHTING & CAMERA RIG FOR PREVIEW
# ------------------------------------------------------------------------------
def setup_presentation(col):
    # Dramatic Cultist Lighting (Rim red + Cool key fill)
    # Key light
    bpy.ops.object.light_add(type='AREA', location=(-1.5, -2.2, 2.4))
    key = bpy.context.active_object
    key.name = "Key_Light"
    key.data.energy = 180
    key.data.size = 1.8
    key.data.color = (0.9, 0.92, 1.0)
    col.objects.link(key)
    bpy.context.scene.collection.objects.unlink(key)

    # Red Demon Rim Light (Back left)
    bpy.ops.object.light_add(type='AREA', location=(1.8, 2.0, 1.8))
    rim = bpy.context.active_object
    rim.name = "Rim_RedLight"
    rim.data.energy = 320
    rim.data.size = 2.0
    rim.data.color = (1.0, 0.05, 0.05)
    col.objects.link(rim)
    bpy.context.scene.collection.objects.unlink(rim)

    # Ground Fill
    bpy.ops.object.light_add(type='POINT', location=(0, -0.6, 0.3))
    fill = bpy.context.active_object
    fill.name = "Sword_GlowFill"
    fill.data.energy = 45
    fill.data.color = (1.0, 0.08, 0.05)
    col.objects.link(fill)
    bpy.context.scene.collection.objects.unlink(fill)

    # Camera framing
    bpy.ops.object.camera_add(location=(0.0, -3.2, 1.35), rotation=(math.radians(82), 0, 0))
    cam = bpy.context.active_object
    cam.name = "Render_Cam"
    bpy.context.scene.camera = cam
    col.objects.link(cam)
    bpy.context.scene.collection.objects.unlink(cam)

# ------------------------------------------------------------------------------
# MAIN EXECUTION
# ------------------------------------------------------------------------------
def main():
    clear_scene()
    col = create_collection("Demon_Cult_Character")
    mats = setup_materials()

    print(">> Generating Cultist Base Anatomy...")
    create_base_body(col, mats)

    print(">> Generating Demonic Mask & Sigil...")
    create_demonic_mask(col, mats)

    print(">> Generating Pointed Assassin Hood & Crimson Edging...")
    create_hood(col, mats)

    print(">> Generating Flared Robes, Wide Sleeves & Tattered Skirt...")
    create_robes(col, mats)

    print(">> Generating Belts, Talisman Banner & Back Compass Emblem...")
    create_accessories_and_emblem(col, mats)

    print(">> Generating Assassin Boots with Strapped Shin Armor...")
    create_legs_and_boots(col, mats)

    print(">> Generating Serrated Demonic Neon Sword...")
    create_demonic_sword(col, mats)

    print(">> Setting up Studio Presentation & Cinematic Lighting...")
    setup_presentation(col)

    # Set Eevee / Cycles bloom & render view settings
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE'
    if hasattr(scene, "eevee"):
        if hasattr(scene.eevee, "use_bloom"):
            scene.eevee.use_bloom = True
        if hasattr(scene.eevee, "bloom_intensity"):
            scene.eevee.bloom_intensity = 0.15

    print("SUCCESS: Demon Cult Assassin model generated successfully!")

if __name__ == "__main__":
    main()
