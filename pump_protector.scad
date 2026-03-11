// ============================================
// Wasser PB-60EA Booster Pump Protector
// Shared parameters and modules
// ============================================
// Include this file in pump_protector_body.scad
// and pump_protector_lid.scad.
// ============================================

// --- Main Parameters ---
box_length = 180;   // X dimension (mm)
box_width  = 140;   // Y dimension (mm)
box_height = 160;   // Z dimension (mm)
wall       = 3;     // Wall thickness (mm)
floor_th   = 5;     // Floor thickness (mm)

// --- Lid Parameters ---
lid_top_th    = 5;    // Solid top plate thickness (mm)
lip_height    = 15;   // Outer grip skirt depth (mm)
lip_clearance = 0.4;  // Gap for easy fit (mm per side)

// --- Pipe Cutout Parameters ---
cut_width        = 50;   // Width of horseshoe cut (mm)
cut_radius       = cut_width / 2;
pipe_notch_depth = 50;   // How far the U-shape cuts down from the top (mm)

// --- Rounded Edge Parameters ---
corner_radius = 5;

// --- Pyramid Parameters ---
pyramid_overhang = 5;    // How far pyramid base extends beyond lid on each side (mm)
pyramid_height   = 20;   // Height of the pyramid above the lid plate (mm)
pyramid_wall     = 3;    // Wall thickness of the hollow pyramid shell (mm)

// --- Resolution ---
$fn = 60;

// ============================================
// Modules
// ============================================

// Horseshoe (U-shape) notch cut from top of wall
module horseshoe_cutout(r, notch_depth, depth) {
    rotate([90, 0, 0])
        linear_extrude(height = depth, center = true)
            union() {
                circle(r = r);
                translate([-r, 0, 0])
                    square([r * 2, notch_depth]);
            }
}

// Rounded box primitive
module rounded_box(l, w, h, r) {
    hull() {
        for (x = [r, l - r])
            for (y = [r, w - r])
                translate([x, y, 0])
                    cylinder(r = r, h = h);
    }
}

// Solid rectangular pyramid
// Origin: centered at base center, base at z=0, apex at z=h
module solid_pyramid(base_l, base_w, h) {
    hull() {
        // Base rectangle at z=0
        translate([-base_l/2, -base_w/2, 0])
            cube([base_l, base_w, 0.01]);
        // Apex point at z=h
        translate([0, 0, h])
            sphere(d=0.02);
    }
}

// Body (with floor, open top)
module protector_body() {
    body_h = box_height - lid_top_th;

    difference() {
        rounded_box(box_length, box_width, body_h, corner_radius);

        // Hollow interior
        translate([wall, wall, floor_th])
            rounded_box(
                box_length - 2 * wall,
                box_width  - 2 * wall,
                body_h - floor_th + 1,
                max(corner_radius - wall, 1)
            );

        // Pipe cutout 1: Left side
        translate([0, box_width / 2, body_h - pipe_notch_depth])
            rotate([0, 0, 90])
                horseshoe_cutout(cut_radius, pipe_notch_depth + 1, wall * 3);

        // Pipe cutout 2: Right side
        translate([box_length, box_width / 2, body_h - pipe_notch_depth])
            rotate([0, 0, 90])
                horseshoe_cutout(cut_radius, pipe_notch_depth + 1, wall * 3);
    }
}

// Lid (solid top + outer grip skirt)
module protector_lid() {
    grip_wall   = wall;
    grip_length = box_length + 2 * (grip_wall + lip_clearance);
    grip_width  = box_width  + 2 * (grip_wall + lip_clearance);
    grip_r      = corner_radius + grip_wall + lip_clearance;

    union() {
        rounded_box(grip_length, grip_width, lid_top_th, grip_r);

        translate([0, 0, -lip_height])
            difference() {
                rounded_box(grip_length, grip_width, lip_height, grip_r);

                translate([grip_wall + lip_clearance, grip_wall + lip_clearance, -1])
                    rounded_box(
                        box_length,
                        box_width,
                        lip_height + 2,
                        corner_radius
                    );
            };
    }
}

// Pyramid cap (sits on top of the lid)
module protector_pyramid() {
    grip_wall   = wall;
    grip_length = box_length + 2 * (grip_wall + lip_clearance);
    grip_width  = box_width  + 2 * (grip_wall + lip_clearance);

    pyr_base_l = grip_length + 2 * pyramid_overhang;
    pyr_base_w = grip_width  + 2 * pyramid_overhang;

    solid_pyramid(pyr_base_l, pyr_base_w, pyramid_height);
}
