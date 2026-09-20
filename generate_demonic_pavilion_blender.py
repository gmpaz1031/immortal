# ==============================================================================
# DEMONIC PAVILION (5-TIER) PROCEDURAL BLENDER PYTHON GENERATOR
# ==============================================================================
# Instructions for Blender:
# 1. Open Blender (3.0+ or 4.0+).
# 2. Go to the "Scripting" workspace tab at the top bar.
# 3. Click "+ New" to create a new text block.
# 4. Paste this entire script into the editor.
# 5. Click "Run Script" (or press Alt + P).
# ==============================================================================

import bpy
import math
from mathutils import Vector, Euler

def create_material(name, base_color, roughness=0.5, metallic=0.0, emission_color=None, emission_strength=0.0):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    if principled:
        # Base Color
        if "Base Color" in principled.inputs:
            principled.inputs["Base Color"].default_value = base_color
        # Roughness & Metallic
        if "Roughness" in principled.inputs:
            principled.inputs["Roughness"].default_value = roughness
        if "Metallic" in principled.inputs:
            principled.inputs["Metallic"].default_value = metallic
        # Emission (Blender 4.0 vs older node layout support)
        if emission_color and emission_strength > 0:
            if "Emission Color" in principled.inputs:
                principled.inputs["Emission Color"].default_value = emission_color
                principled.inputs["Emission Strength"].default_value = emission_strength
            elif "Emission" in principled.inputs:
                principled.inputs["Emission"].default_value = emission_color
    return mat

def assign_material(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)

def build_demonic_pavilion():
    # 1. Setup Collection
    coll_name = "DemonicPavilion_5Tier"
    collection = bpy.data.collections.get(coll_name)
    if collection is None:
        collection = bpy.data.collections.new(coll_name)
        bpy.context.scene.collection.children.link(collection)

    # Helper function to link object to our collection
    def link_obj(obj):
        for c in obj.users_collection:
            c.objects.unlink(obj)
        collection.objects.link(obj)

    # 2. Build Material Palette
    mat_stone    = create_material("Mat_BasaltStone", (0.12, 0.12, 0.15, 1.0), roughness=0.85, metallic=0.1)
    mat_timber   = create_material("Mat_DarkTimber",  (0.16, 0.08, 0.06, 1.0), roughness=0.6,  metallic=0.0)
    mat_roof     = create_material("Mat_ObsidianRoof", (0.08, 0.07, 0.09, 1.0), roughness=0.3,  metallic=0.2)
    mat_crimson  = create_material("Mat_CrimsonTrim", (0.65, 0.08, 0.08, 1.0), roughness=0.4,  emission_color=(0.5, 0.05, 0.05, 1.0), emission_strength=1.5)
    mat_horn     = create_material("Mat_DemonHorn",   (0.85, 0.10, 0.10, 1.0), roughness=0.2,  emission_color=(0.9, 0.1, 0.1, 1.0), emission_strength=3.0)
    mat_lantern  = create_material("Mat_LanternGlow", (1.0,  0.25, 0.08, 1.0), roughness=0.1,  emission_color=(1.0, 0.25, 0.08, 1.0), emission_strength=5.0)

    # 3. Foundation Base Platform
    base_w, base_d, base_h = 24.0, 24.0, 3.0
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, base_h * 0.5))
    base_obj = bpy.context.active_object
    base_obj.name = "Foundation_Base"
    base_obj.scale = (base_w, base_d, base_h)
    assign_material(base_obj, mat_stone)
    link_obj(base_obj)

    # Entrance Steps (Front)
    stair_count = 6
    stair_w = 7.0
    stair_depth = 5.0
    for i in range(stair_count):
        step_h = base_h / stair_count
        step_d = stair_depth / stair_count
        pos_z = (i + 0.5) * step_h
        pos_y = -(base_d * 0.5) - (i + 0.5) * step_d
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, pos_y, pos_z))
        step = bpy.context.active_object
        step.name = f"Foundation_Stair_{i+1}"
        step.scale = (stair_w, step_d, step_h)
        assign_material(step, mat_stone)
        link_obj(step)

    # 4. Build 5 Tiered Floors
    current_z = base_h

    for tier in range(1, 6):
        # Tapering floor dimensions for 5 tiers
        floor_w = 20.0 - (tier * 2.0)
        floor_d = 20.0 - (tier * 2.0)
        floor_h = 5.0

        # Floor Slab
        slab_h = 0.6
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, current_z + (slab_h * 0.5)))
        slab = bpy.context.active_object
        slab.name = f"Tier{tier}_Slab"
        slab.scale = (floor_w + 2.0, floor_d + 2.0, slab_h)
        assign_material(slab, mat_timber)
        link_obj(slab)

        # Balustrade Railings around perimeter
        rail_h = 1.1
        rail_thick = 0.25
        rail_z = current_z + slab_h + (rail_h * 0.5)
        rail_off_x = (floor_w * 0.5) + 0.8
        rail_off_y = (floor_d * 0.5) + 0.8

        rails_data = [
            (0, -rail_off_y, floor_w + 1.6, rail_thick), # Front
            (0,  rail_off_y, floor_w + 1.6, rail_thick), # Back
            (-rail_off_x, 0, rail_thick, floor_d + 1.6), # Left
            ( rail_off_x, 0, rail_thick, floor_d + 1.6)  # Right
        ]
        for idx, (rx, ry, rw, rd) in enumerate(rails_data):
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(rx, ry, rail_z))
            r_obj = bpy.context.active_object
            r_obj.name = f"Tier{tier}_Rail_{idx+1}"
            r_obj.scale = (rw, rd, rail_h)
            assign_material(r_obj, mat_timber)
            link_obj(r_obj)

        # Inner Chamber Walls
        chamber_z = current_z + slab_h + (floor_h * 0.5)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, chamber_z))
        chamber = bpy.context.active_object
        chamber.name = f"Tier{tier}_Chamber"
        chamber.scale = (floor_w - 1.5, floor_d - 1.5, floor_h)
        assign_material(chamber, mat_timber)
        link_obj(chamber)

        # 4 Corner Pillars (Columns)
        col_off_x = (floor_w * 0.5) - 0.8
        col_off_y = (floor_d * 0.5) - 0.8
        col_corners = [
            ( col_off_x,  col_off_y),
            (-col_off_x,  col_off_y),
            ( col_off_x, -col_off_y),
            (-col_off_x, -col_off_y)
        ]
        for c_idx, (cx, cy) in enumerate(col_corners):
            bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=floor_h, location=(cx, cy, chamber_z))
            col_obj = bpy.context.active_object
            col_obj.name = f"Tier{tier}_Pillar_{c_idx+1}"
            assign_material(col_obj, mat_timber)
            link_obj(col_obj)

        # 5. Sweeping Flared Roof Eaves for Tier
        roof_z = current_z + slab_h + floor_h
        roof_overhang = 2.4
        roof_w = floor_w + (roof_overhang * 2.0)
        roof_d = floor_d + (roof_overhang * 2.0)
        roof_h = 1.0

        # Main Roof Eaves Plate
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, roof_z + (roof_h * 0.5)))
        roof_obj = bpy.context.active_object
        roof_obj.name = f"Tier{tier}_RoofEaves"
        roof_obj.scale = (roof_w, roof_d, roof_h)
        assign_material(roof_obj, mat_roof)
        link_obj(roof_obj)

        # Crimson Trim Edge
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, roof_z + (roof_h * 0.2)))
        trim_obj = bpy.context.active_object
        trim_obj.name = f"Tier{tier}_CrimsonTrim"
        trim_obj.scale = (roof_w + 0.3, roof_d + 0.3, 0.3)
        assign_material(trim_obj, mat_crimson)
        link_obj(trim_obj)

        # 4 Demon Horn Corner Finials
        horn_corners = [
            ( roof_w * 0.5,  roof_d * 0.5, math.radians(45)),
            (-roof_w * 0.5,  roof_d * 0.5, math.radians(135)),
            ( roof_w * 0.5, -roof_d * 0.5, math.radians(-45)),
            (-roof_w * 0.5, -roof_d * 0.5, math.radians(-135))
        ]
        for h_idx, (hx, hy, rot_z) in enumerate(horn_corners):
            bpy.ops.mesh.primitive_cone_add(radius1=0.4, depth=2.0, location=(hx, hy, roof_z + 1.2), rotation=(math.radians(20), 0, rot_z))
            horn_obj = bpy.context.active_object
            horn_obj.name = f"Tier{tier}_Horn_{h_idx+1}"
            assign_material(horn_obj, mat_horn)
            link_obj(horn_obj)

            # Crimson Glowing Lantern at Roof Corner
            bpy.ops.mesh.primitive_uv_sphere_add(radius=0.45, location=(hx, hy, roof_z - 1.0))
            lant_obj = bpy.context.active_object
            lant_obj.name = f"Tier{tier}_Lantern_{h_idx+1}"
            assign_material(lant_obj, mat_lantern)
            link_obj(lant_obj)

            # Blender Point Light attached to lantern
            light_data = bpy.data.lights.new(name=f"Tier{tier}_LanternLight_{h_idx+1}", type='POINT')
            light_data.color = (1.0, 0.25, 0.08)
            light_data.energy = 40.0
            light_obj = bpy.data.objects.new(name=f"Tier{tier}_LanternLight_{h_idx+1}", object_data=light_data)
            light_obj.location = (hx, hy, roof_z - 1.0)
            collection.objects.link(light_obj)

        current_z = roof_z + roof_h

    # 6. Top Spire Crown Finial
    bpy.ops.mesh.primitive_cone_add(radius1=0.8, depth=5.0, location=(0, 0, current_z + 2.5))
    spire_obj = bpy.context.active_object
    spire_obj.name = "Top_Spire_Crown"
    assign_material(spire_obj, mat_horn)
    link_obj(spire_obj)

    print("[Demonic Pavilion] 5-Tier Demonic Pavilion procedurally generated in Blender successfully!")

# Run procedural generation
build_demonic_pavilion()
