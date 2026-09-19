"""
High-fidelity Stylized 3D GLB Generator for Arcane Apprentice (SpellArena).
Sculpts a high-detail stylized anime character strictly matching the approved design in IMAGE 5.
"""

import json
import struct
import math
import os

class GLBBuilder:
    def __init__(self):
        self.buffer = bytearray()
        self.buffer_views = []
        self.accessors = []
        self.meshes = []
        self.nodes = []
        self.materials = []
        self.scenes = [{"nodes": []}]

    def add_material(self, name, base_color=(1, 1, 1, 1), metallic=0.0, roughness=0.5, emissive=(0, 0, 0), double_sided=False):
        mat = {
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": [float(c) for c in base_color],
                "metallicFactor": float(metallic),
                "roughnessFactor": float(roughness)
            },
            "doubleSided": double_sided
        }
        if emissive[0] > 0 or emissive[1] > 0 or emissive[2] > 0:
            mat["emissiveFactor"] = [float(c) for c in emissive]
        idx = len(self.materials)
        self.materials.append(mat)
        return idx

    def _add_buffer_data(self, data: bytes, target=None) -> int:
        while len(self.buffer) % 4 != 0:
            self.buffer.append(0)
        offset = len(self.buffer)
        self.buffer.extend(data)
        bv = {
            "buffer": 0,
            "byteOffset": offset,
            "byteLength": len(data)
        }
        if target:
            bv["target"] = target
        idx = len(self.buffer_views)
        self.buffer_views.append(bv)
        return idx

    def add_mesh_primitive(self, positions, normals, uvs, indices, material_idx, name="Mesh"):
        if not positions or not indices:
            return -1

        pos_bytes = bytearray()
        min_pos = [float('inf')] * 3
        max_pos = [float('-inf')] * 3
        for p in positions:
            for i in range(3):
                min_pos[i] = min(min_pos[i], p[i])
                max_pos[i] = max(max_pos[i], p[i])
            pos_bytes.extend(struct.pack('<fff', p[0], p[1], p[2]))
        
        bv_pos = self._add_buffer_data(pos_bytes, target=34962)
        acc_pos = len(self.accessors)
        self.accessors.append({
            "bufferView": bv_pos,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(positions),
            "type": "VEC3",
            "min": min_pos,
            "max": max_pos
        })

        norm_bytes = bytearray()
        for n in normals:
            norm_bytes.extend(struct.pack('<fff', n[0], n[1], n[2]))
        bv_norm = self._add_buffer_data(norm_bytes, target=34962)
        acc_norm = len(self.accessors)
        self.accessors.append({
            "bufferView": bv_norm,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(normals),
            "type": "VEC3"
        })

        uv_bytes = bytearray()
        for u in uvs:
            uv_bytes.extend(struct.pack('<ff', u[0], u[1]))
        bv_uv = self._add_buffer_data(uv_bytes, target=34962)
        acc_uv = len(self.accessors)
        self.accessors.append({
            "bufferView": bv_uv,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(uvs),
            "type": "VEC2"
        })

        idx_bytes = bytearray()
        for idx in indices:
            idx_bytes.extend(struct.pack('<H', idx))
        bv_idx = self._add_buffer_data(idx_bytes, target=34963)
        acc_idx = len(self.accessors)
        self.accessors.append({
            "bufferView": bv_idx,
            "byteOffset": 0,
            "componentType": 5123,
            "count": len(indices),
            "type": "SCALAR"
        })

        mesh_idx = len(self.meshes)
        self.meshes.append({
            "name": name,
            "primitives": [{
                "attributes": {
                    "POSITION": acc_pos,
                    "NORMAL": acc_norm,
                    "TEXCOORD_0": acc_uv
                },
                "indices": acc_idx,
                "material": material_idx
            }]
        })
        return mesh_idx

    def add_node(self, name, mesh_idx=None, translation=(0,0,0), rotation=(0,0,0,1), scale=(1,1,1), children=None):
        node = {"name": name}
        if mesh_idx is not None and mesh_idx >= 0:
            node["mesh"] = mesh_idx
        if translation != (0,0,0):
            node["translation"] = list(translation)
        if rotation != (0,0,0,1):
            node["rotation"] = list(rotation)
        if scale != (1,1,1):
            node["scale"] = list(scale)
        if children:
            node["children"] = children
        node_idx = len(self.nodes)
        self.nodes.append(node)
        return node_idx

    def build_glb(self, output_path: str):
        gltf = {
            "asset": {
                "version": "2.0",
                "generator": "SpellArena Arcane Apprentice Master 3D Generator"
            },
            "scenes": self.scenes,
            "nodes": self.nodes,
            "materials": self.materials,
            "meshes": self.meshes,
            "buffers": [{"byteLength": len(self.buffer)}],
            "bufferViews": self.buffer_views,
            "accessors": self.accessors
        }

        json_str = json.dumps(gltf, separators=(',', ':'))
        json_bytes = json_str.encode('utf-8')
        while len(json_bytes) % 4 != 0:
            json_bytes += b' '

        while len(self.buffer) % 4 != 0:
            self.buffer.append(0)

        total_length = 12 + 8 + len(json_bytes) + 8 + len(self.buffer)
        header = struct.pack('<4sII', b'glTF', 2, total_length)
        json_chunk_header = struct.pack('<II', len(json_bytes), 0x4E4F534A)
        bin_chunk_header = struct.pack('<II', len(self.buffer), 0x004E4942)

        os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
        with open(output_path, 'wb') as f:
            f.write(header)
            f.write(json_chunk_header)
            f.write(json_bytes)
            f.write(bin_chunk_header)
            f.write(self.buffer)
        print(f"[GLB Builder] Master model generated: {output_path} ({total_length} bytes)")


# ==========================================
# GEOMETRY GENERATION HELPERS
# ==========================================

class MeshCollector:
    def __init__(self):
        self.groups = {}

    def add_triangle(self, mat_idx, p0, p1, p2, n0=None, n1=None, n2=None, uv0=(0,0), uv1=(1,0), uv2=(0.5,1)):
        if mat_idx not in self.groups:
            self.groups[mat_idx] = {'positions': [], 'normals': [], 'uvs': [], 'indices': []}
        g = self.groups[mat_idx]
        base_idx = len(g['positions'])
        if n0 is None or n1 is None or n2 is None:
            ax, ay, az = p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]
            bx, by, bz = p2[0] - p0[0], p2[1] - p0[1], p2[2] - p0[2]
            nx = ay * bz - az * by
            ny = az * bx - ax * bz
            nz = ax * by - ay * bx
            length = math.sqrt(nx*nx + ny*ny + nz*nz) or 1.0
            fn = (nx/length, ny/length, nz/length)
            n0, n1, n2 = fn, fn, fn

        g['positions'].extend([p0, p1, p2])
        g['normals'].extend([n0, n1, n2])
        g['uvs'].extend([uv0, uv1, uv2])
        g['indices'].extend([base_idx, base_idx + 1, base_idx + 2])

    def add_quad(self, mat_idx, p0, p1, p2, p3, n0=None, n1=None, n2=None, n3=None, uv0=(0,0), uv1=(1,0), uv2=(1,1), uv3=(0,1)):
        self.add_triangle(mat_idx, p0, p1, p2, n0, n1, n2, uv0, uv1, uv2)
        self.add_triangle(mat_idx, p0, p2, p3, n0, n2, n3, uv0, uv2, uv3)

    def add_smooth_ellipsoid(self, mat_idx, center, radii, rings=16, sectors=20, taper_y=0.0, flatten_z=0.0):
        cx, cy, cz = center
        rx, ry, rz = radii
        verts = []
        norms = []
        uvs = []
        for r in range(rings + 1):
            theta = math.pi * r / rings
            sin_t = math.sin(theta)
            cos_t = math.cos(theta)
            y_norm = cos_t
            taper = 1.0 + taper_y * (y_norm - 0.5)
            for s in range(sectors + 1):
                phi = 2.0 * math.pi * s / sectors
                sin_p = math.sin(phi)
                cos_p = math.cos(phi)

                nx = sin_t * math.cos(phi)
                ny = cos_t
                nz = sin_t * math.sin(phi)

                # Flatten back or front if requested
                fz = 1.0 + flatten_z if nz < 0 else 1.0
                px = cx + rx * nx * taper
                py = cy + ry * ny
                pz = cz + rz * nz * taper * fz

                verts.append((px, py, pz))
                norms.append((nx, ny, nz))
                uvs.append((s / sectors, r / rings))

        for r in range(rings):
            for s in range(sectors):
                i0 = r * (sectors + 1) + s
                i1 = i0 + 1
                i2 = (r + 1) * (sectors + 1) + s
                i3 = i2 + 1
                self.add_triangle(mat_idx, verts[i0], verts[i2], verts[i1], norms[i0], norms[i2], norms[i1], uvs[i0], uvs[i2], uvs[i1])
                self.add_triangle(mat_idx, verts[i1], verts[i2], verts[i3], norms[i1], norms[i2], norms[i3], uvs[i1], uvs[i2], uvs[i3])

    def add_cylinder(self, mat_idx, p_bottom, p_top, r_bottom, r_top, segments=16, cap_bottom=True, cap_top=True):
        bx, by, bz = p_bottom
        tx, ty, tz = p_top
        dx, dy, dz = tx - bx, ty - by, tz - bz
        height = math.sqrt(dx*dx + dy*dy + dz*dz) or 1.0
        ux, uy, uz = dx/height, dy/height, dz/height
        if abs(ux) < 0.9 and abs(uz) < 0.9:
            vx, vy, vz = 1.0, 0.0, 0.0
        else:
            vx, vy, vz = 0.0, 1.0, 0.0
        wx = uy*vz - uz*vy
        wy = uz*vx - ux*vz
        wz = ux*vy - uy*vx
        wlen = math.sqrt(wx*wx + wy*wy + wz*wz) or 1.0
        wx, wy, wz = wx/wlen, wy/wlen, wz/wlen
        vx = wy*uz - wz*uy
        vy = wz*ux - wx*uz
        vz = wx*uy - wy*ux

        bot_ring = []
        top_ring = []
        bot_norms = []
        top_norms = []

        for s in range(segments + 1):
            angle = 2.0 * math.pi * s / segments
            c = math.cos(angle)
            sn = math.sin(angle)
            nx = vx * c + wx * sn
            ny = vy * c + wy * sn
            nz = vz * c + wz * sn

            pb = (bx + r_bottom * nx, by + r_bottom * ny, bz + r_bottom * nz)
            pt = (tx + r_top * nx, ty + r_top * ny, tz + r_top * nz)
            bot_ring.append(pb)
            top_ring.append(pt)
            bot_norms.append((nx, ny, nz))
            top_norms.append((nx, ny, nz))

        for s in range(segments):
            p0 = bot_ring[s]
            p1 = bot_ring[s+1]
            p2 = top_ring[s+1]
            p3 = top_ring[s]
            n0, n1, n2, n3 = bot_norms[s], bot_norms[s+1], top_norms[s+1], top_norms[s]
            self.add_quad(mat_idx, p0, p1, p2, p3, n0, n1, n2, n3)

        if cap_bottom:
            nb = (-ux, -uy, -uz)
            for s in range(segments):
                self.add_triangle(mat_idx, p_bottom, bot_ring[s+1], bot_ring[s], nb, nb, nb)
        if cap_top:
            nt = (ux, uy, uz)
            for s in range(segments):
                self.add_triangle(mat_idx, p_top, top_ring[s], top_ring[s+1], nt, nt, nt)

    def add_hair_clump(self, mat_idx, origin, target, mid_offset, base_radius, mid_radius, tip_radius=0.005, segments=8):
        """Creates a smooth, stylized anime hair clump with organic curvature."""
        ox, oy, oz = origin
        tx, ty, tz = target
        mx = (ox + tx) * 0.5 + mid_offset[0]
        my = (oy + ty) * 0.5 + mid_offset[1]
        mz = (oz + tz) * 0.5 + mid_offset[2]
        
        # 3-segment quadratic spline
        steps = 4
        points = []
        radii = []
        for i in range(steps + 1):
            t = i / steps
            # Quadratic Bezier
            inv = 1.0 - t
            px = inv * inv * ox + 2.0 * inv * t * mx + t * t * tx
            py = inv * inv * oy + 2.0 * inv * t * my + t * t * ty
            pz = inv * inv * oz + 2.0 * inv * t * mz + t * t * tz
            points.append((px, py, pz))
            if t < 0.5:
                r = base_radius * (1.0 - t*2.0) + mid_radius * (t*2.0)
            else:
                r = mid_radius * (1.0 - (t-0.5)*2.0) + tip_radius * ((t-0.5)*2.0)
            radii.append(r)

        for i in range(steps):
            self.add_cylinder(mat_idx, points[i], points[i+1], radii[i], radii[i+1], segments=segments, cap_bottom=(i==0), cap_top=(i==steps-1))

    def add_faceted_crystal(self, mat_idx, center, size, height):
        cx, cy, cz = center
        sx, sz = size[0], size[1]
        top = (cx, cy + height * 0.5, cz)
        bot = (cx, cy - height * 0.5, cz)
        ring = []
        segments = 8
        for i in range(segments):
            angle = 2.0 * math.pi * i / segments
            rx = cx + sx * math.cos(angle)
            rz = cz + sz * math.sin(angle)
            ring.append((rx, cy, rz))

        for i in range(segments):
            p0 = ring[i]
            p1 = ring[(i + 1) % segments]
            self.add_triangle(mat_idx, top, p1, p0)
            self.add_triangle(mat_idx, bot, p0, p1)

    def add_curved_cloth_ribbon(self, mat_idx, path, widths, double_sided=True):
        n_pts = len(path)
        if n_pts < 2:
            return
        left_verts = []
        right_verts = []
        normals = []

        for i in range(n_pts):
            p = path[i]
            w = widths[i]
            if i < n_pts - 1:
                tangent = (path[i+1][0] - p[0], path[i+1][1] - p[1], path[i+1][2] - p[2])
            else:
                tangent = (p[0] - path[i-1][0], p[1] - path[i-1][1], p[2] - path[i-1][2])
            
            tlen = math.sqrt(tangent[0]**2 + tangent[1]**2 + tangent[2]**2) or 1.0
            tx, ty, tz = tangent[0]/tlen, tangent[1]/tlen, tangent[2]/tlen

            up = (0, 1, 0)
            if abs(ty) > 0.95:
                up = (0, 0, 1)
            
            sx = ty * up[2] - tz * up[1]
            sy = tz * up[0] - tx * up[2]
            sz = tx * up[1] - ty * up[0]
            slen = math.sqrt(sx*sx + sy*sy + sz*sz) or 1.0
            sx, sy, sz = sx/slen, sy/slen, sz/slen

            nx = sy * tz - sz * ty
            ny = sz * tx - sx * tz
            nz = sx * ty - sy * tx

            l_pt = (p[0] - sx * w * 0.5, p[1] - sy * w * 0.5, p[2] - sz * w * 0.5)
            r_pt = (p[0] + sx * w * 0.5, p[1] + sy * w * 0.5, p[2] + sz * w * 0.5)
            left_verts.append(l_pt)
            right_verts.append(r_pt)
            normals.append((nx, ny, nz))

        for i in range(n_pts - 1):
            p0 = left_verts[i]
            p1 = right_verts[i]
            p2 = right_verts[i+1]
            p3 = left_verts[i+1]
            n0, n1 = normals[i], normals[i+1]
            self.add_quad(mat_idx, p0, p1, p2, p3, n0, n0, n1, n1)
            if double_sided:
                nb0 = (-n0[0], -n0[1], -n0[2])
                nb1 = (-n1[0], -n1[1], -n1[2])
                self.add_quad(mat_idx, p1, p0, p3, p2, nb0, nb0, nb1, nb1)


# ==========================================
# MASTER ARCANE APPRENTICE ASSEMBLY
# ==========================================

def generate_arcane_apprentice(output_glb_path: str):
    builder = GLBBuilder()
    collector = MeshCollector()

    # Materials Palette strictly matching IMAGE 5:
    # 1. Warm Anime Skin (Youthful, warm peachy tone)
    mat_skin = builder.add_material("Mat_Skin", base_color=(0.95, 0.78, 0.68, 1.0), roughness=0.6)
    # 2. Dark Navy Mage Tunic (Rich deep indigo navy)
    mat_navy = builder.add_material("Mat_NavyTunic", base_color=(0.10, 0.15, 0.28, 1.0), roughness=0.7)
    # 3. Cream Parchment Robe Panels
    mat_cream = builder.add_material("Mat_CreamRobe", base_color=(0.88, 0.84, 0.74, 1.0), roughness=0.65, double_sided=True)
    # 4. Polished Antique Gold Trim
    mat_gold = builder.add_material("Mat_GoldTrim", base_color=(0.85, 0.68, 0.22, 1.0), metallic=0.7, roughness=0.35)
    # 5. Crimson Scarf & Flowing Cape
    mat_crimson = builder.add_material("Mat_CrimsonCape", base_color=(0.68, 0.11, 0.14, 1.0), roughness=0.55, double_sided=True)
    # 6. Adventurer Leather (Boots, gloves, pouch)
    mat_leather = builder.add_material("Mat_BrownLeather", base_color=(0.26, 0.16, 0.10, 1.0), roughness=0.75)
    # 7. Dark Leather Soles / Accents
    mat_leather_dark = builder.add_material("Mat_DarkLeather", base_color=(0.14, 0.09, 0.06, 1.0), roughness=0.85)
    # 8. Dark Brown Messy Anime Hair
    mat_hair = builder.add_material("Mat_DarkHair", base_color=(0.13, 0.09, 0.07, 1.0), roughness=0.7)
    # 9. Expressive Anime Eyes
    mat_eye_dark = builder.add_material("Mat_EyeIris", base_color=(0.06, 0.04, 0.03, 1.0), roughness=0.15)
    mat_eye_white = builder.add_material("Mat_EyeWhite", base_color=(0.96, 0.96, 0.96, 1.0), roughness=0.2)
    mat_eye_glow = builder.add_material("Mat_EyeHighlight", base_color=(1.0, 1.0, 1.0, 1.0), emissive=(0.9, 0.9, 0.9), roughness=0.1)
    # 10. Gnarled Mahogany Staff Wood
    mat_wood = builder.add_material("Mat_StaffWood", base_color=(0.30, 0.18, 0.11, 1.0), roughness=0.8)
    # 11. Glowing Azure Arcane Crystal (Amulet & Staff Tip)
    mat_crystal = builder.add_material("Mat_ArcaneCrystal", base_color=(0.1, 0.85, 1.0, 1.0), metallic=0.1, roughness=0.15, emissive=(0.15, 0.85, 1.0))
    # 12. Floating Magic Rune Ring
    mat_rune = builder.add_material("Mat_RuneAura", base_color=(0.2, 0.88, 1.0, 0.8), emissive=(0.25, 0.9, 1.0), double_sided=True)

    print("[Master Generator] Building high-poly sculpted Arcane Apprentice...")

    # -------------------------------------------------------------
    # 1. HEAD & ANIME FACE (Centered at Y=1.38, clearly separated from scarf)
    # -------------------------------------------------------------
    head_center = (0.0, 1.38, 0.0)
    collector.add_smooth_ellipsoid(mat_skin, head_center, (0.165, 0.185, 0.175), rings=18, sectors=22, taper_y=-0.22)
    
    # Stylized Anime Chin & Jawline
    collector.add_smooth_ellipsoid(mat_skin, (0.0, 1.25, 0.06), (0.085, 0.065, 0.075), rings=10, sectors=14, taper_y=-0.35)

    # Stylized Ears
    collector.add_smooth_ellipsoid(mat_skin, (-0.17, 1.36, -0.02), (0.032, 0.055, 0.042), rings=8, sectors=10)
    collector.add_smooth_ellipsoid(mat_skin, (0.17, 1.36, -0.02), (0.032, 0.055, 0.042), rings=8, sectors=10)

    # Expressive Anime Eyes (Almond shape, white sclera, dark iris, reflection glints)
    for side in (-1, 1):
        ex = side * 0.068
        # Sclera
        collector.add_smooth_ellipsoid(mat_eye_white, (ex, 1.38, 0.155), (0.035, 0.032, 0.016), rings=8, sectors=12)
        # Iris & Pupil
        collector.add_smooth_ellipsoid(mat_eye_dark, (ex + side*0.003, 1.38, 0.165), (0.024, 0.027, 0.010), rings=8, sectors=12)
        # Highlight Glint
        collector.add_smooth_ellipsoid(mat_eye_glow, (ex + side*0.009, 1.392, 0.172), (0.007, 0.007, 0.005), rings=6, sectors=8)
        # Eyelid top line
        collector.add_cylinder(mat_eye_dark, (ex - side*0.028, 1.412, 0.15), (ex + side*0.028, 1.412, 0.15), 0.005, 0.004, segments=6)
        # Eyebrow Arch
        collector.add_cylinder(mat_hair, (ex - side*0.032, 1.442, 0.142), (ex + side*0.028, 1.450, 0.138), 0.006, 0.005, segments=6)

    # Nose (subtle stylized anime bridge & tip)
    collector.add_smooth_ellipsoid(mat_skin, (0.0, 1.32, 0.175), (0.016, 0.018, 0.018), rings=6, sectors=8)

    # Mouth (determined closed smile line)
    collector.add_cylinder(mat_eye_dark, (-0.026, 1.275, 0.152), (0.026, 1.275, 0.152), 0.004, 0.004, segments=4)

    # -------------------------------------------------------------
    # 2. LAYERED VOLUMETRIC ANIME HAIR (Natural curved clumps matching IMAGE 5)
    # -------------------------------------------------------------
    # Main Hair Cap
    collector.add_smooth_ellipsoid(mat_hair, (0.0, 1.43, -0.03), (0.19, 0.165, 0.19), rings=16, sectors=20)
    
    # Layered Front Bangs (Sweeping naturally across forehead)
    bang_specs = [
        ((0.0, 1.50, 0.12), (0.04, 1.37, 0.18), (0.02, 0.03, 0.03), 0.038, 0.045),
        ((-0.06, 1.49, 0.11), (-0.09, 1.36, 0.17), (-0.03, 0.03, 0.03), 0.038, 0.045),
        ((0.07, 1.49, 0.11), (0.10, 1.36, 0.17), (0.03, 0.03, 0.03), 0.038, 0.045),
        ((-0.12, 1.46, 0.08), (-0.15, 1.34, 0.14), (-0.03, 0.02, 0.02), 0.035, 0.040),
        ((0.13, 1.46, 0.08), (0.16, 1.34, 0.14), (0.03, 0.02, 0.02), 0.035, 0.040),
        ((-0.03, 1.52, 0.13), (-0.02, 1.40, 0.19), (0.0, 0.02, 0.03), 0.032, 0.038),
    ]
    for orig, targ, mid_off, br, mr in bang_specs:
        collector.add_hair_clump(mat_hair, orig, targ, mid_off, br, mr, segments=8)

    # Sideburn Locks (Left & Right framing cheeks)
    for side in (-1, 1):
        collector.add_hair_clump(mat_hair, (side * 0.15, 1.42, 0.04), (side * 0.17, 1.28, 0.08), (side * 0.02, 0.01, 0.02), 0.040, 0.045, segments=8)
        collector.add_hair_clump(mat_hair, (side * 0.16, 1.38, 0.0), (side * 0.18, 1.26, -0.02), (side * 0.02, 0.01, 0.0), 0.036, 0.040, segments=8)

    # Top Crown Spikes (Stylized anime silhouette from all 360° angles)
    crown_specs = [
        ((0.0, 1.52, 0.0), (0.03, 1.66, 0.06), (0.02, 0.03, 0.02), 0.045, 0.048),
        ((-0.07, 1.51, 0.02), (-0.14, 1.65, 0.05), (-0.03, 0.03, 0.02), 0.045, 0.048),
        ((0.08, 1.51, 0.01), (0.15, 1.65, 0.04), (0.03, 0.03, 0.02), 0.045, 0.048),
        ((-0.12, 1.48, -0.05), (-0.22, 1.58, -0.08), (-0.04, 0.02, -0.01), 0.042, 0.045),
        ((0.13, 1.48, -0.05), (0.23, 1.58, -0.08), (0.04, 0.02, -0.01), 0.042, 0.045),
        ((0.0, 1.50, -0.10), (0.0, 1.63, -0.18), (0.0, 0.03, -0.03), 0.045, 0.048),
        ((-0.07, 1.46, -0.12), (-0.12, 1.56, -0.20), (-0.02, 0.02, -0.02), 0.040, 0.042),
        ((0.08, 1.46, -0.12), (0.13, 1.56, -0.20), (0.02, 0.02, -0.02), 0.040, 0.042),
    ]
    for orig, targ, mid_off, br, mr in crown_specs:
        collector.add_hair_clump(mat_hair, orig, targ, mid_off, br, mr, segments=8)

    # Back Hair Layer (Tapering towards neck)
    back_specs = [
        ((0.0, 1.38, -0.14), (0.0, 1.24, -0.18), (0.0, -0.02, 0.02), 0.045, 0.048),
        ((-0.08, 1.36, -0.13), (-0.10, 1.24, -0.17), (-0.02, -0.02, 0.02), 0.042, 0.045),
        ((0.08, 1.36, -0.13), (0.10, 1.24, -0.17), (0.02, -0.02, 0.02), 0.042, 0.045),
    ]
    for orig, targ, mid_off, br, mr in back_specs:
        collector.add_hair_clump(mat_hair, orig, targ, mid_off, br, mr, segments=8)

    # -------------------------------------------------------------
    # 3. NECK & CRIMSON SCARF / COWL (Folded fabric below chin Y=1.12 to 1.22)
    # -------------------------------------------------------------
    collector.add_cylinder(mat_skin, (0.0, 1.15, 0.0), (0.0, 1.28, 0.0), 0.068, 0.072, segments=12)

    # Folded Crimson Scarf Cowl (Thick rounded cloth folds)
    collector.add_cylinder(mat_crimson, (0.0, 1.12, 0.01), (0.0, 1.21, 0.01), 0.17, 0.155, segments=18, cap_bottom=True, cap_top=True)
    collector.add_cylinder(mat_crimson, (0.0, 1.14, 0.03), (0.0, 1.22, 0.035), 0.18, 0.165, segments=18, cap_bottom=True, cap_top=True)
    # Front scarf knot / overlap
    collector.add_smooth_ellipsoid(mat_crimson, (0.0, 1.16, 0.135), (0.075, 0.045, 0.045), rings=8, sectors=12)

    # -------------------------------------------------------------
    # 4. FLOWING CRIMSON CAPE (Attached beneath cowl, sweeping back & twin swallowtails)
    # -------------------------------------------------------------
    cape_path_center = [
        (0.0, 1.15, -0.09),
        (0.0, 1.01, -0.15),
        (0.0, 0.85, -0.19),
        (0.0, 0.67, -0.23),
        (0.0, 0.48, -0.25)
    ]
    cape_widths = [0.35, 0.40, 0.42, 0.38, 0.32]
    collector.add_curved_cloth_ribbon(mat_crimson, cape_path_center, cape_widths)

    # Left Swallowtail
    tail_l = [
        (-0.08, 0.54, -0.21),
        (-0.14, 0.40, -0.25),
        (-0.19, 0.24, -0.29),
        (-0.23, 0.10, -0.31)
    ]
    collector.add_curved_cloth_ribbon(mat_crimson, tail_l, [0.14, 0.12, 0.08, 0.02])

    # Right Swallowtail
    tail_r = [
        (0.08, 0.54, -0.21),
        (0.14, 0.40, -0.25),
        (0.19, 0.24, -0.29),
        (0.23, 0.10, -0.31)
    ]
    collector.add_curved_cloth_ribbon(mat_crimson, tail_r, [0.14, 0.12, 0.08, 0.02])

    # Golden Diamond Runes on Cape Tails (As in IMAGE 5!)
    collector.add_faceted_crystal(mat_gold, (-0.13, 0.34, -0.26), (0.028, 0.028), 0.01)
    collector.add_faceted_crystal(mat_gold, (0.13, 0.34, -0.26), (0.028, 0.028), 0.01)

    # -------------------------------------------------------------
    # 5. TORSO, NAVY TUNIC & GOLD HARNESS STRAPS
    # -------------------------------------------------------------
    # Chest & Upper Torso (Deep Midnight Navy)
    collector.add_cylinder(mat_navy, (0.0, 0.94, 0.0), (0.0, 1.14, 0.0), 0.165, 0.195, segments=16, cap_bottom=True, cap_top=True)
    # Midriff & Waist (Tapered)
    collector.add_cylinder(mat_navy, (0.0, 0.76, 0.0), (0.0, 0.94, 0.0), 0.150, 0.165, segments=16, cap_bottom=True, cap_top=True)

    # Cream Tunic V-Collar Insert
    collector.add_cylinder(mat_cream, (0.0, 0.99, 0.02), (0.0, 1.13, 0.02), 0.12, 0.14, segments=12)

    # Gold Harness Straps
    collector.add_cylinder(mat_gold, (-0.07, 0.80, 0.125), (-0.09, 1.11, 0.105), 0.011, 0.011, segments=6)
    collector.add_cylinder(mat_gold, (0.07, 0.80, 0.125), (0.09, 1.11, 0.105), 0.011, 0.011, segments=6)

    # -------------------------------------------------------------
    # 6. GLOWING CHEST AMULET (Faceted cyan crystal mounted with gold clasp)
    # -------------------------------------------------------------
    amulet_pos = (0.0, 1.01, 0.15)
    collector.add_smooth_ellipsoid(mat_gold, amulet_pos, (0.038, 0.038, 0.016), rings=8, sectors=12)
    collector.add_faceted_crystal(mat_crystal, (0.0, 1.01, 0.17), (0.026, 0.026), 0.055)

    # -------------------------------------------------------------
    # 7. LEATHER BELT, GOLD BUCKLE & ADVENTURER POUCH
    # -------------------------------------------------------------
    belt_y = 0.77
    collector.add_cylinder(mat_leather, (0.0, belt_y - 0.035, 0.0), (0.0, belt_y + 0.035, 0.0), 0.160, 0.160, segments=18, cap_bottom=True, cap_top=True)
    # Gold Square Buckle
    collector.add_cylinder(mat_gold, (0.0, belt_y, 0.150), (0.0, belt_y, 0.170), 0.036, 0.036, segments=4)
    collector.add_cylinder(mat_leather_dark, (0.0, belt_y, 0.167), (0.0, belt_y, 0.175), 0.020, 0.020, segments=4)
    # Adventurer Pouch on Right Hip
    pouch_pos = (0.155, belt_y - 0.05, 0.05)
    collector.add_smooth_ellipsoid(mat_leather, pouch_pos, (0.042, 0.052, 0.036), rings=8, sectors=10)
    collector.add_smooth_ellipsoid(mat_gold, (pouch_pos[0], pouch_pos[1] + 0.016, pouch_pos[2] + 0.030), (0.009, 0.009, 0.007), rings=6, sectors=8)

    # -------------------------------------------------------------
    # 8. CREAM ROBE OVER-PANELS & GOLD TRIMS (Flared coat tails over thighs)
    # -------------------------------------------------------------
    fl_path = [
        (-0.05, belt_y - 0.02, 0.135),
        (-0.09, 0.60, 0.165),
        (-0.13, 0.44, 0.185),
        (-0.16, 0.30, 0.195)
    ]
    collector.add_curved_cloth_ribbon(mat_cream, fl_path, [0.12, 0.14, 0.15, 0.14])
    collector.add_cylinder(mat_gold, (-0.08, 0.30, 0.195), (-0.24, 0.30, 0.195), 0.009, 0.009, segments=6)

    fr_path = [
        (0.05, belt_y - 0.02, 0.135),
        (0.09, 0.60, 0.165),
        (0.13, 0.44, 0.185),
        (0.16, 0.30, 0.195)
    ]
    collector.add_curved_cloth_ribbon(mat_cream, fr_path, [0.12, 0.14, 0.15, 0.14])
    collector.add_cylinder(mat_gold, (0.08, 0.30, 0.195), (0.24, 0.30, 0.195), 0.009, 0.009, segments=6)

    # Side Panels
    for side in (-1, 1):
        side_path = [
            (side * 0.135, belt_y - 0.02, 0.0),
            (side * 0.175, 0.58, 0.0),
            (side * 0.195, 0.42, 0.0),
            (side * 0.205, 0.28, 0.0)
        ]
        collector.add_curved_cloth_ribbon(mat_cream, side_path, [0.15, 0.17, 0.17, 0.15])
        collector.add_cylinder(mat_gold, (side * 0.205, 0.28, -0.075), (side * 0.205, 0.28, 0.075), 0.008, 0.008, segments=6)

    # Back Robe Tails (Under cape)
    back_robe = [
        (0.0, belt_y - 0.02, -0.125),
        (0.0, 0.58, -0.155),
        (0.0, 0.42, -0.165),
        (0.0, 0.28, -0.175)
    ]
    collector.add_curved_cloth_ribbon(mat_cream, back_robe, [0.22, 0.26, 0.26, 0.24])

    # -------------------------------------------------------------
    # 9. LEGS, DARK TROUSERS & FANTASY ADVENTURER BOOTS
    # -------------------------------------------------------------
    for side in (-1, 1):
        leg_x = side * 0.10
        # Upper Thighs (Dark Navy Trousers)
        collector.add_cylinder(mat_navy, (leg_x, 0.42, 0.0), (leg_x, 0.74, 0.0), 0.072, 0.085, segments=12)
        # Knees
        collector.add_smooth_ellipsoid(mat_navy, (leg_x, 0.42, 0.02), (0.072, 0.065, 0.072), rings=8, sectors=10)
        
        # Leather Adventurer Boots
        boot_top_y = 0.40
        collector.add_cylinder(mat_leather, (leg_x, boot_top_y - 0.035, 0.01), (leg_x, boot_top_y + 0.025, 0.01), 0.082, 0.086, segments=14)
        collector.add_cylinder(mat_leather, (leg_x, 0.12, 0.01), (leg_x, boot_top_y, 0.01), 0.066, 0.078, segments=14)
        foot_center = (leg_x, 0.07, 0.06)
        collector.add_smooth_ellipsoid(mat_leather, foot_center, (0.065, 0.058, 0.11), rings=10, sectors=14)
        collector.add_cylinder(mat_leather_dark, (leg_x, 0.0, 0.05), (leg_x, 0.03, 0.05), 0.066, 0.066, segments=14)
        collector.add_cylinder(mat_gold, (leg_x - 0.04, 0.18, 0.07), (leg_x + 0.04, 0.18, 0.07), 0.006, 0.006, segments=6)

    # -------------------------------------------------------------
    # 10. ARMS, GLOVES & HANDS
    # -------------------------------------------------------------
    # Left Arm (Gripping staff)
    l_shoulder = (-0.20, 1.05, 0.0)
    l_elbow = (-0.26, 0.85, 0.04)
    l_wrist = (-0.23, 0.68, 0.18)
    l_hand = (-0.22, 0.64, 0.22)

    collector.add_smooth_ellipsoid(mat_cream, l_shoulder, (0.07, 0.06, 0.06), rings=8, sectors=10)
    collector.add_cylinder(mat_gold, (-0.16, 1.03, 0.0), (-0.24, 1.03, 0.0), 0.066, 0.066, segments=10)
    collector.add_cylinder(mat_navy, l_elbow, l_shoulder, 0.058, 0.066, segments=10)
    collector.add_cylinder(mat_leather, l_wrist, l_elbow, 0.055, 0.060, segments=10)
    collector.add_smooth_ellipsoid(mat_leather, l_hand, (0.044, 0.040, 0.044), rings=8, sectors=10)
    collector.add_cylinder(mat_leather, (-0.24, 0.64, 0.20), (-0.20, 0.64, 0.24), 0.020, 0.020, segments=8)

    # Right Arm (Ready stance)
    r_shoulder = (0.20, 1.05, 0.0)
    r_elbow = (0.27, 0.83, -0.02)
    r_wrist = (0.24, 0.65, 0.08)
    r_hand = (0.23, 0.58, 0.12)

    collector.add_smooth_ellipsoid(mat_cream, r_shoulder, (0.07, 0.06, 0.06), rings=8, sectors=10)
    collector.add_cylinder(mat_gold, (0.16, 1.03, 0.0), (0.24, 1.03, 0.0), 0.066, 0.066, segments=10)
    collector.add_cylinder(mat_navy, r_elbow, r_shoulder, 0.058, 0.066, segments=10)
    collector.add_cylinder(mat_leather, r_wrist, r_elbow, 0.055, 0.060, segments=10)
    collector.add_smooth_ellipsoid(mat_leather, r_hand, (0.046, 0.040, 0.048), rings=8, sectors=10)

    # -------------------------------------------------------------
    # 11. GNARLED MAGE STAFF & GLOWING ARCANE CRYSTAL (Left hand)
    # -------------------------------------------------------------
    staff_base = (-0.22, 0.0, 0.22)
    staff_grip = (-0.22, 0.64, 0.22)
    staff_neck = (-0.22, 1.34, 0.22)

    # Gnarled wood shaft with natural knots
    collector.add_cylinder(mat_wood, staff_base, staff_grip, 0.019, 0.022, segments=10)
    collector.add_cylinder(mat_wood, staff_grip, staff_neck, 0.022, 0.025, segments=10)

    # 4 curling root prongs cradling crystal
    for i in range(4):
        prong_angle = math.pi * 0.5 * i
        px = staff_neck[0] + 0.040 * math.cos(prong_angle)
        pz = staff_neck[2] + 0.040 * math.sin(prong_angle)
        prong_path = [
            (staff_neck[0], staff_neck[1], staff_neck[2]),
            (px, staff_neck[1] + 0.07, pz),
            (px * 1.03, staff_neck[1] + 0.14, pz * 1.03),
            (staff_neck[0] + 0.016 * math.cos(prong_angle), staff_neck[1] + 0.21, staff_neck[2] + 0.016 * math.sin(prong_angle))
        ]
        collector.add_curved_cloth_ribbon(mat_wood, prong_path, [0.028, 0.024, 0.018, 0.010])

    # Faceted Arcane Blue Crystal at Staff Tip
    crystal_center = (staff_neck[0], staff_neck[1] + 0.13, staff_neck[2])
    collector.add_faceted_crystal(mat_crystal, crystal_center, (0.055, 0.055), 0.12)

    # Magic Orbital Rune Ring
    rune_verts = []
    rune_segs = 16
    for i in range(rune_segs + 1):
        ang = 2.0 * math.pi * i / rune_segs
        rx = crystal_center[0] + 0.090 * math.cos(ang)
        ry = crystal_center[1] + 0.022 * math.sin(ang * 2.0)
        rz = crystal_center[2] + 0.090 * math.sin(ang)
        rune_verts.append((rx, ry, rz))
    for i in range(rune_segs):
        p0 = rune_verts[i]
        p1 = rune_verts[i+1]
        collector.add_cylinder(mat_rune, p0, p1, 0.006, 0.006, segments=4)

    # -------------------------------------------------------------
    # BUILD GLB MESH PRIMITIVES & SCENE NODES
    # -------------------------------------------------------------
    print(f"[Master Generator] Compiling {len(collector.groups)} material groups...")
    
    mesh_indices = []
    for mat_idx, data in collector.groups.items():
        if not data['positions']:
            continue
        mesh_name = f"Mesh_Mat_{mat_idx}"
        m_idx = builder.add_mesh_primitive(
            data['positions'],
            data['normals'],
            data['uvs'],
            data['indices'],
            mat_idx,
            name=mesh_name
        )
        if m_idx >= 0:
            mesh_indices.append(m_idx)

    children_nodes = []
    for m_idx in mesh_indices:
        node_id = builder.add_node(f"Part_{m_idx}", mesh_idx=m_idx)
        children_nodes.append(node_id)

    cast_point_node = builder.add_node("CastPoint", translation=list(crystal_center))
    children_nodes.append(cast_point_node)

    root_node = builder.add_node("ArcaneApprentice", children=children_nodes)
    builder.scenes[0]["nodes"].append(root_node)

    builder.build_glb(output_glb_path)


if __name__ == "__main__":
    out_path = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "models", "arcane_apprentice.glb")
    generate_arcane_apprentice(out_path)
