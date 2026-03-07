// ============================================
// Wasser PB-60EA Booster Pump Protector
// Two-piece design: Body + Lid
// ============================================
// Print both pieces separately.
// Body: print with open top facing up.
// Lid:  print flat (top surface on build plate).
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
cut_width       = 50;   // Width of horseshoe cut (mm)
cut_radius      = cut_width / 2;

// Horseshoe notch depth from top of body wall
pipe_notch_depth = 50;  // How far the U-shape cuts down from the top (mm)

// --- Rounded Edge Parameters ---
corner_radius = 5;

// --- Part Selection ---
// Set to "body", "lid", or "both" to render
render_part = "both";

// Spacing between parts when rendering "both"
both_spacing = 20;

// --- Resolution ---
$fn = 60;

// ============================================
// Modules
// ============================================

// Horseshoe (U-shape) notch cut from top of wall
// Creates a semicircle at the bottom with a rectangular slot up to the top
module horseshoe_cutout(r, notch_depth, depth) {
    rotate([90, 0, 0])
        linear_extrude(height = depth, center = true)
            union() {
                // Semicircle at bottom of notch
                circle(r = r);
                // Rectangle from circle center up to top
                translate([-r, 0, 0])
                    square([r * 2, notch_depth]);
            }
}

// Wide horseshoe for pipe + cable (symmetric, wider U)
module wide_horseshoe_cutout(r, extra_w, notch_depth, depth) {
    wider_r = r + extra_w / 2;  // Symmetrically widen
    rotate([90, 0, 0])
        linear_extrude(height = depth, center = true)
            union() {
                // Wider semicircle at bottom of notch
                circle(r = wider_r);
                // Rectangle from circle center up to top
                translate([-wider_r, 0, 0])
                    square([wider_r * 2, notch_depth]);
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

// ============================================
// Body (with floor, open top)
// ============================================
module protector_body() {
    body_h = box_height - lid_top_th;

    difference() {
        // Outer shell
        rounded_box(box_length, box_width, body_h, corner_radius);

        // Hollow interior (starts above floor, open top)
        translate([wall, wall, floor_th])
            rounded_box(
                box_length - 2 * wall,
                box_width  - 2 * wall,
                body_h - floor_th + 1,
                max(corner_radius - wall, 1)
            );

        // Pipe cutout 1: Input pipe (left side, horseshoe from top)
        translate([0, box_width / 2, body_h - pipe_notch_depth])
            rotate([0, 0, 90])
                horseshoe_cutout(cut_radius, pipe_notch_depth + 1, wall * 3);

        // Pipe cutout 2: Output pipe + cable (right side, horseshoe from top)
        translate([box_length, box_width / 2, body_h - pipe_notch_depth])
            rotate([0, 0, 90])
                horseshoe_cutout(cut_radius, pipe_notch_depth + 1, wall * 3);
    }
}

// ============================================
// Lid (solid top + outer grip skirt)
// ============================================
module protector_lid() {
    grip_wall = wall;                     // Grip skirt wall thickness

    // Total outer size of the grip skirt
    grip_length = box_length + 2 * (grip_wall + lip_clearance);
    grip_width  = box_width  + 2 * (grip_wall + lip_clearance);
    grip_r      = corner_radius + grip_wall + lip_clearance;

    union() {
        // Solid top plate (no holes)
        rounded_box(grip_length, grip_width, lid_top_th, grip_r);

        // Outer grip skirt (wraps down around the body walls)
        translate([0, 0, -lip_height])
            difference() {
                rounded_box(grip_length, grip_width, lip_height, grip_r);

                // Hollow: body fits inside with clearance
                translate([grip_wall + lip_clearance, grip_wall + lip_clearance, -1])
                    rounded_box(
                        box_length,
                        box_width,
                        lip_height + 2,
                        corner_radius
                    );
            }
    }
}

// ============================================
// Render
// ============================================

if (render_part == "body") {
    protector_body();
}
else if (render_part == "lid") {
    // Flipped for printing: top plate on build plate, grip skirt up
    grip_offset = wall + lip_clearance;
    translate([grip_offset, grip_offset, lid_top_th])
        rotate([180, 0, 0])
            protector_lid();
}
else {  // "both"
    // Body at origin
    protector_body();

    // Lid behind the body (along Y), flipped for printing
    grip_offset = wall + lip_clearance;
    grip_length_full = box_length + 2 * (wall + lip_clearance);
    grip_width_full  = box_width  + 2 * (wall + lip_clearance);
    translate([-grip_offset, box_width + both_spacing + grip_width_full, lid_top_th])
        rotate([180, 0, 0])
            protector_lid();
}

// ============================================
// Print Notes:
// ============================================
// Body:
//   - Print as-is (floor on build plate, open top facing up)
//   - No supports needed (teardrop cutouts are support-free)
//
// Lid:
//   - Print upside down (top surface on build plate)
//   - The lip faces up during printing
//   - No supports needed
//
// To export STL for each part separately:
//   1. Set render_part = "body", render (F6), export STL
//   2. Set render_part = "lid",  render (F6), export STL
//
// Recommended settings:
//   - Layer height: 0.2mm
//   - Infill: 15-20% (PETG/ASA) or 25-30% (TPU)
//   - Perimeters: 3 for good water resistance
// ============================================
