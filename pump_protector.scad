// ============================================
// Wasser PB-60EA Booster Pump Protector
// Shared parameters and modules
// ============================================
// Include this file in pump_protector_body.scad
// and pump_protector_lid.scad.
// ============================================

// --- Main Parameters ---
box_length = 180;   // X dimension (mm)
box_width  = 155;   // Y dimension (mm) (Depth from front to back)
box_height = 140;   // Z dimension (mm) (Height from floor to top)
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

// Horizontal Horseshoe (U-shape) notch cut from front wall towards back,
// with a 45-degree teardrop/chamfered roof to print without supports.
module horizontal_cutout(r, notch_depth, depth) {
    rotate([0, 90, 0])
        linear_extrude(height = depth, center = true)
            union() {
                // The circular part for the pipe
                circle(r = r);
                
                // The bottom flat part of the slot
                translate([0, -notch_depth])
                    square([r, notch_depth]);
                
                // The 45-degree self-supporting roof polygon
                polygon([
                    [0, -notch_depth],                               // V1: Bottom left of top part
                    [0, 0],                                          // V2: Center of circle
                    [-r * sqrt(2)/2, r * sqrt(2)/2],                 // V3: 45-deg tangent on circle
                    [-r * sqrt(2), 0],                               // V4: Teardrop peak
                    [-(r * sqrt(2) + notch_depth), -notch_depth]     // V5: Top left roof
                ]);
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

        // Hollow interior (CDHG open top, solid floor at AEBF)
        translate([wall, wall, floor_th])
            rounded_box(
                box_length - 2 * wall,
                box_width  - 2 * wall,
                body_h - floor_th + 1,
                max(corner_radius - wall, 1)
            );

        // Pipe cutout 1: Left side (Horizontal, stopped before front wall)
        translate([0, pipe_notch_depth, (box_height / 2) - 20])
            horizontal_cutout(cut_radius, pipe_notch_depth - wall, wall * 3);

        // Pipe cutout 2: Right side (Horizontal, stopped before front wall)
        translate([box_length, pipe_notch_depth, (box_height / 2) - 20])
            horizontal_cutout(cut_radius, pipe_notch_depth - wall, wall * 3);
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

// Corner labels for easier rotation reference
module corner_labels(l, w, h) {
    color("red") {
        // Bottom corners (Z=0)
        translate([-20, -20, 0]) linear_extrude(1) text("A", size=15, halign="center", valign="center");
        translate([l + 20, -20, 0]) linear_extrude(1) text("B", size=15, halign="center", valign="center");
        translate([l + 20, w + 20, 0]) linear_extrude(1) text("C", size=15, halign="center", valign="center");
        translate([-20, w + 20, 0]) linear_extrude(1) text("D", size=15, halign="center", valign="center");
        
        // Top corners (Z=h)
        translate([-20, -20, h]) linear_extrude(1) text("E", size=15, halign="center", valign="center");
        translate([l + 20, -20, h]) linear_extrude(1) text("F", size=15, halign="center", valign="center");
        translate([l + 20, w + 20, h]) linear_extrude(1) text("G", size=15, halign="center", valign="center");
        translate([-20, w + 20, h]) linear_extrude(1) text("H", size=15, halign="center", valign="center");
    }
}
