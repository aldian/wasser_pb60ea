// ============================================
// Wasser PB-60EA Booster Pump Protector — LID
// Print upside down (top surface on build plate).
// No supports needed.
// Size: ~187 x 147 x 20 mm
// ============================================

include <pump_protector.scad>

// Flip so top plate sits on build plate, grip skirt faces up
grip_offset = wall + lip_clearance;
translate([grip_offset, grip_offset, lid_top_th])
    rotate([180, 0, 0])
        protector_lid();
