// ==============================================================================
// PARAMETRIC UNDER-DESK & WALL MULTI-CABLE CLAMP
// Designed for MakerWorld Customizer | 100% Zero-Support FDM Printing
// ==============================================================================

// PRESET_SMALL: cable_diameter=3.5; num_slots=2; mount_style="screw";
// PRESET_LARGE: cable_diameter=8.0; num_slots=5; mount_style="screw";

/* [Cable Configuration] */
// Diameter of the cables to organize (mm)
cable_diameter = 5.5; // [3.0:0.5:12.0]

// Number of cable channels
num_slots = 4; // [1:1:8]

// Spacing between adjacent cable channels (mm)
slot_spacing = 3.0; // [2.0:0.5:6.0]

// Snap retention lip gap ratio (fraction of cable diameter)
retention_gap_ratio = 0.68; // [0.55:0.01:0.85]

/* [Mounting Method] */
// Select mounting style
mount_style = "screw"; // [screw:Screw Mount Wings, vhb:Flat Base for VHB Tape, both:Screw Wings + VHB Recess]

// Screw shank clearance diameter (mm)
screw_hole_d = 4.0; // [3.0:0.5:5.5]

// Screw countersink head diameter (mm)
countersink_d = 7.5; // [5.0:0.5:10.0]

/* [Structural Dimensions] */
// Base plate thickness under cables (mm)
base_thickness = 2.5; // [2.0:0.2:4.5]

// Wall thickness between channels and exterior (mm)
wall_thickness = 2.5; // [2.0:0.2:4.5]

// Clamp depth along cable run (mm)
clamp_depth = 14.0; // [10.0:1.0:25.0]

// Corner fillet radius (mm)
fillet_r = 1.2; // [0.5:0.1:2.0]

/* [Advanced] */
// Circle smoothness resolution
$fn = 64;

// ------------------------------------------------------------------------------
// Internal Derived Dimensions
// ------------------------------------------------------------------------------
eps = 0.08;

body_height = base_thickness + cable_diameter + wall_thickness;
body_width = num_slots * cable_diameter + (num_slots - 1) * slot_spacing + 2 * wall_thickness;

wing_width = (mount_style == "screw" || mount_style == "both") ? 13.0 : 0.0;
wing_height = base_thickness + 1.2;
total_width = body_width + 2 * wing_width;

// Center position of cable circle in Z
cable_cz = base_thickness + cable_diameter / 2;

// Snap opening gap width
gap_w = cable_diameter * retention_gap_ratio;

// ------------------------------------------------------------------------------
// Geometry Modules
// ------------------------------------------------------------------------------

module rounded_cube(size, r) {
    // 2D rounded rectangle extruded along Z or smooth hull
    x = size[0];
    y = size[1];
    z = size[2];
    hull() {
        translate([r, r, 0]) cylinder(r=r, h=z);
        translate([x - r, r, 0]) cylinder(r=r, h=z);
        translate([x - r, y - r, 0]) cylinder(r=r, h=z);
        translate([r, y - r, 0]) cylinder(r=r, h=z);
    }
}

module solid_body() {
    // Main cable housing
    translate([wing_width, 0, 0])
        rounded_cube([body_width, clamp_depth, body_height], fillet_r);

    // Left and right mounting wings if screw mount is enabled
    if (wing_width > 0) {
        hull() {
            translate([0, 0, 0])
                rounded_cube([wing_width + fillet_r, clamp_depth, wing_height], fillet_r);
            translate([wing_width, 0, 0])
                cube([fillet_r, clamp_depth, wing_height + 1.0]);
        }
        hull() {
            translate([total_width - wing_width - fillet_r, 0, 0])
                rounded_cube([wing_width + fillet_r, clamp_depth, wing_height], fillet_r);
            translate([total_width - wing_width - fillet_r, 0, 0])
                cube([fillet_r, clamp_depth, wing_height + 1.0]);
        }
    }
}

module cable_cutouts() {
    for (i = [0 : num_slots - 1]) {
        slot_cx = wing_width + wall_thickness + cable_diameter / 2 + i * (cable_diameter + slot_spacing);
        
        // Circular cable channel
        translate([slot_cx, -eps, cable_cz])
            rotate([-90, 0, 0])
            cylinder(d=cable_diameter, h=clamp_depth + 2 * eps);

        // Snap vertical exit channel
        translate([slot_cx - gap_w / 2, -eps, cable_cz])
            cube([gap_w, clamp_depth + 2 * eps, body_height - cable_cz + eps]);

        // 45-degree snap lead-in ramp on top for smooth push-in
        lead_in_depth = (body_height - cable_cz) * 0.45;
        translate([slot_cx, -eps, body_height - lead_in_depth])
            rotate([-90, 0, 0])
            hull() {
                translate([-gap_w / 2, 0, 0])
                    cube([gap_w, lead_in_depth + 2 * eps, clamp_depth + 2 * eps]);
                translate([-(gap_w / 2 + lead_in_depth * 0.9), lead_in_depth + eps, 0])
                    cube([gap_w + 2 * lead_in_depth * 0.9, eps, clamp_depth + 2 * eps]);
            }
    }
}

module screw_holes() {
    if (wing_width > 0) {
        // Left wing screw hole
        left_x = wing_width / 2;
        mount_cy = clamp_depth / 2;
        
        translate([left_x, mount_cy, -eps]) {
            cylinder(d=screw_hole_d, h=wing_height + 2 * eps);
            // Countersink cone
            translate([0, 0, wing_height - (countersink_d - screw_hole_d) / 2])
                cylinder(d1=screw_hole_d, d2=countersink_d, h=(countersink_d - screw_hole_d) / 2 + eps);
            translate([0, 0, wing_height + (countersink_d - screw_hole_d) / 2 - 0.01])
                cylinder(d=countersink_d, h=5);
        }

        // Right wing screw hole
        right_x = total_width - wing_width / 2;
        translate([right_x, mount_cy, -eps]) {
            cylinder(d=screw_hole_d, h=wing_height + 2 * eps);
            // Countersink cone
            translate([0, 0, wing_height - (countersink_d - screw_hole_d) / 2])
                cylinder(d1=screw_hole_d, d2=countersink_d, h=(countersink_d - screw_hole_d) / 2 + eps);
            translate([0, 0, wing_height + (countersink_d - screw_hole_d) / 2 - 0.01])
                cylinder(d=countersink_d, h=5);
        }
    }
}

module vhb_tape_recess() {
    if (mount_style == "vhb" || mount_style == "both") {
        recess_depth = 0.5;
        margin = 1.5;
        translate([wing_width + margin, margin, -eps])
            cube([body_width - 2 * margin, clamp_depth - 2 * margin, recess_depth + eps]);
    }
}

// ------------------------------------------------------------------------------
// Final Assembly
// ------------------------------------------------------------------------------
difference() {
    solid_body();
    cable_cutouts();
    screw_holes();
    vhb_tape_recess();
}
