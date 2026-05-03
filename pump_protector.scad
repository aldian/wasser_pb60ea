// ============================================
// Wasser PB-60EA Booster Pump Protector
// Shared parameters and modules
// ============================================
// Include this file in pump_protector_body.scad
// and pump_protector_lid.scad.
// ============================================

// --- Main Parameters ---
box_length = 135;   // X dimension (mm)
box_width  = 155;   // Y dimension (mm) (Depth from front to back)
box_height = 110;   // Z dimension (mm) (Height from floor to top)
wall       = 3;     // Wall thickness (mm)
floor_th   = 5;     // Floor thickness (mm)
leg_height   = 40;    // Height of bottom legs (mm)
leg_inset    = 15;    // Leg center distance from the box edges
leg_r_top    = 12;    // Radius of leg at the box junction (wider for strength)
leg_r_bottom = 7;     // Radius of leg at the ground

// --- Lid Parameters ---
lid_top_th    = 5;    // Solid top plate thickness (mm)
lip_height    = 25;   // Outer grip skirt depth (mm)
lip_clearance = 0.4;  // Gap for easy fit (mm per side)

// --- Pipe Cutout Parameters ---
cut_width        = 30;   // Width of horseshoe cut (mm)
cut_radius       = cut_width / 2;
pipe_notch_depth = 50;   // How far the U-shape cuts down from the top (mm)

// --- Rounded Edge Parameters ---
corner_radius = 5;

// --- Pyramid Parameters ---
pyramid_overhang = 19;   // How far pyramid base extends beyond lid on each side (mm)
pyramid_height   = 22;   // Height of the pyramid above the lid plate (mm)
pyramid_wall     = 3;    // Wall thickness of the hollow pyramid shell (mm)
pyramid_top_r    = 2;    // Radius of the rounded apex (mm)

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
    // We use minkowski to uniformly round all faces, edges, and corners.
    // A hemisphere is used instead of a full sphere to prevent the bottom from curling under (overhang).
    r = pyramid_top_r; 
    
    minkowski() {
        hull() {
            // Base rectangle at z=0, shrunk by 2*r so minkowski restores it to full size
            translate([-(base_l - 2*r)/2, -(base_w - 2*r)/2, 0])
                cube([base_l - 2*r, base_w - 2*r, 0.01]);
            
            // Apex point, lowered so final height is exactly h
            translate([0, 0, h - r])
                cube([0.01, 0.01, 0.01], center=true);
        }
        // Upward-facing hemisphere to avoid under-curling
        difference() {
            sphere(r = r, $fn=30);
            translate([0, 0, -r])
                cube([2*r+2, 2*r+2, 2*r], center=true);
        }
    }
}

// Body (with floor, open top)
module protector_body() {
    body_h = box_height - lid_top_th;

    union() {
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
            translate([0, pipe_notch_depth, 55])
                horizontal_cutout(cut_radius, pipe_notch_depth - wall, wall * 3);

            // Pipe cutout 2: Right side (Horizontal, stopped before front wall)
            translate([box_length, pipe_notch_depth, 55])
                horizontal_cutout(cut_radius, pipe_notch_depth - wall, wall * 3);

            // 40mm diameter hole on the floor near corner C (back-right)
            // Positioned slightly away from the inner right (BC) and back (CD) walls
            translate([box_length - 28, box_width - 28, -1])
                cylinder(d = 40, h = floor_th + 2);

            // Drainage pores (12mm diameter) on a 30mm grid, shifted 5mm towards AD side and 3mm towards CD side
            for (x = [25 : 30 : box_length - 30]) {
                for (y = [33 : 30 : box_width - 30]) {
                    // Only place a pore if it doesn't intersect the 40mm cabling hole
                    if (norm([x - (box_length - 28), y - (box_width - 28)]) > 30) {
                        translate([x, y, -1])
                            cylinder(d = 12, h = floor_th + 2);
                    }
                }
            }
        }

        // Add 8 legs at the bottom (corners + side centers + exact center)
        leg_positions = [
            // 3 Corners (Omitted corner C / back-right to keep cabling hole clear)
            [leg_inset, leg_inset],
            [box_length - leg_inset, leg_inset],
            [leg_inset, box_width - leg_inset],
            // 4 Side Centers (AB, BC, CD, AD)
            [box_length / 2, leg_inset],
            [box_length - leg_inset, box_width / 2],
            [box_length / 2, box_width - leg_inset],
            [leg_inset, box_width / 2],
            // 1 Bottom Center
            [box_length / 2, box_width / 2]
        ];

        for (pos = leg_positions) {
            translate([pos[0], pos[1], -leg_height])
                cylinder(r1 = leg_r_bottom, r2 = leg_r_top, h = leg_height);
        }
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
