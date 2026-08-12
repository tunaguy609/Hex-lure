$fn = 96;

// Head dimensions - longer, tapered body
head_length = 80;  // Much longer body
head_diameter_front = 24;  // Front (widest)
head_diameter_rear = 18;   // Rear (narrower, tapers to collar)
head_radius_front = head_diameter_front / 2;
head_radius_rear = head_diameter_rear / 2;
edge_round = 1.2;

// Bullet nose - rounded dome
nose_length = 20;  // Length of rounded nose section
nose_radius = head_radius_front * 1.2;  // Sphere radius for dome

// Cup dish nose
cup_diameter = 18;
cup_depth = 5;
cup_radius = ((cup_diameter / 2) * (cup_diameter / 2) + cup_depth * cup_depth) / (2 * cup_depth);

// Skirt collar
collar_length = 24;
collar_section_length = collar_length / 2;
collar_max_diameter = 19;
collar_neck_diameter = 17;
skirt_bore_diameter = 16.25;
skirt_pocket_extension = 20;

// Internal features
leader_bore_diameter = 2.2;
jet_diameter = 2.2;

// Eye recesses
eye_diameter = 8;
eye_depth = 2.5;
eye_x = 40;  // Moved to body, not head-collar junction
eye_surface_offset = 12.5;

// Jet parameters
jet_exit_x = 70;
jet_exit_y = 10.25;
jet_exit_z = 3.75;
jet_entry_offset = 4.25;

function hex_points(radius) = [
    for (i = [0:5]) [radius * cos(60 * i + 30), radius * sin(60 * i + 30)]
];

function hex_radius_at(x) = head_radius_front - (x / (head_length + nose_length)) * (head_radius_front - head_radius_rear);

module rounded_hex_profile(radius, roundover) {
    offset(r = roundover)
        polygon(points = hex_points(radius - roundover));
}

module bullet_nose() {
    // Dome-shaped rounded nose
    intersection() {
        translate([0, 0, -nose_radius + nose_length])
            sphere(r = nose_radius);
        
        // Constrain to nose length
        translate([-50, -50, -nose_length])
            cube([100, 100, nose_length]);
    }
}

module hex_nose_transition() {
    // Transition from round bullet to hexagonal body
    hull() {
        translate([0, 0, -nose_length])
            rotate([0, 0, 90])
                rotate([90, 0, 0])
                    linear_extrude(height = 0.1)
                        rounded_hex_profile(head_radius_front, edge_round);
        
        translate([0, 0, 0])
            sphere(r = head_radius_front * 0.95);
    }
}

module body_blank() {
    union() {
        // Rounded bullet nose
        bullet_nose();
        
        // Hexagonal body tapered from front to rear
        hull() {
            translate([0, 0, 0])
                rotate([0, 0, 90])
                    rotate([90, 0, 0])
                        linear_extrude(height = 0.1)
                            rounded_hex_profile(head_radius_front, edge_round);
            
            translate([head_length, 0, 0])
                rotate([0, 0, 90])
                    rotate([90, 0, 0])
                        linear_extrude(height = 0.1)
                            rounded_hex_profile(head_radius_rear, edge_round);
        }
    }
}

module head_outer() {
    body_blank();
}

module collar_outer() {
    translate([head_length, 0, 0])
        rotate([0, 90, 0])
            union() {
                cylinder(h = collar_section_length, d1 = collar_max_diameter, d2 = collar_neck_diameter);
                translate([0, 0, collar_section_length])
                    cylinder(h = collar_section_length, d1 = collar_neck_diameter, d2 = collar_max_diameter);
            }
}

module cup_dish() {
    // Cup dish centered on the rounded nose tip
    translate([0, 0, nose_length - cup_depth / 2])
        sphere(r = cup_radius * 0.8);
}

module leader_bore() {
    translate([-nose_length, 0, 0])
        rotate([0, 90, 0])
            cylinder(h = head_length + nose_length - skirt_pocket_extension + 2, d = leader_bore_diameter);
}

module skirt_pocket() {
    translate([head_length - skirt_pocket_extension, 0, 0])
        rotate([0, 90, 0])
            cylinder(h = skirt_pocket_extension + collar_length + 1, d = skirt_bore_diameter);
}

module eye_recesses() {
    for (side = [-1, 1]) {
        translate([eye_x, side * eye_surface_offset, 0])
            rotate([side * 90, 0, 0])
                cylinder(h = eye_depth + 1, d = eye_diameter);
    }
}

module cylinder_between(p1, p2, diameter) {
    v = [p2[0] - p1[0], p2[1] - p1[1], p2[2] - p1[2]];
    length = norm(v);
    axis = [-v[1], v[0], 0];
    angle = length == 0 ? 0 : acos(v[2] / length);

    translate(p1)
        rotate(a = angle, v = norm(axis) < 0.0001 ? [0, 0, 1] : axis)
            cylinder(h = length, d = diameter);
}

module jets() {
    jet_entries = [
        [5, jet_entry_offset, jet_entry_offset],
        [5, -jet_entry_offset, jet_entry_offset],
        [5, jet_entry_offset, -jet_entry_offset],
        [5, -jet_entry_offset, -jet_entry_offset]
    ];

    jet_exits = [
        [jet_exit_x, jet_exit_y, jet_exit_z],
        [jet_exit_x, -jet_exit_y, jet_exit_z],
        [jet_exit_x, jet_exit_y, -jet_exit_z],
        [jet_exit_x, -jet_exit_y, -jet_exit_z]
    ];

    for (i = [0:3]) {
        cylinder_between(jet_entries[i], jet_exits[i], jet_diameter);
    }
}

// Main lure
difference() {
    union() {
        head_outer();
        collar_outer();
    }

    cup_dish();
    leader_bore();
    skirt_pocket();
    eye_recesses();
    jets();
}
