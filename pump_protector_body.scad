// ============================================
// Wasser PB-60EA Booster Pump Protector — BODY
// Print with floor on build plate, open top up.
// No supports needed.
// Size: ~135 x 155 x 150 mm
// ============================================

include <pump_protector.scad>

protector_body();

// Display corner labels for communication reference
corner_labels(box_length, box_width, box_height - lid_top_th);
