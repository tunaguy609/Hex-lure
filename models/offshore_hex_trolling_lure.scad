$fn = 96;

// Head dimensions - longer, tapered body
head_length = 80;  // Much longer body
head_diameter_front = 24;  // Front (widest)
head_diameter_rear = 18;   // Rear (narrower, tapers to collar)
head_radius_front = head_diameter_front / 2;
head_radius_rear = head_diameter_rear / 2;
edge_round = 1.2;

// Rounded nose tip
nose_length = 12;  // Length of rounded nose section
nose_tip_radius = head_radius_front * 0.6;

// Cup dish nose - on the tip surface
cup_diameter = 8;
cup_depth = 2;  // Shallow but visible

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
eye_x = 40;
eye_surface_offset = 12.5;

// Jet parameters
jet_exit_x = 70;
jet_exit_y = 10.25;
jet_exit_z = 3.75;
jet_entry_offset = 3;
jet_entrance_depth = 3;
jet_entrance_diameter = 3;

function hex_points(radius) = [
    for (i = [0:5]) [radius * cos(60 * i + 30), radius * sin(60 * i + 30)]
];

module rounded_hex_profile(radius, roundover) {
    offset(r = roundover)
        polygon(points = hex_points(radius - roundover));
}

module body_blank() {
    // Create rounded nose tip + tapered hex body as one piece using hull
    hull() {
        // Rounded tip at front
        translate([-nose_length, 0, 0])
            sphere(r = nose_tip_radius);
        
        // Front hex section
        translate([0, 0, 0])
            rotate([0, 0, 90])
                rotate([90, 0, 0])
                    linear_extrude(height = 0.1)
                        rounded_hex_profile(head_radius_front, edge_round);
        
        // Rear hex section (tapered)
        translate([head_length, 0, 0])
            rotate([0, 0, 90])
                rotate([90, 0, 0])
                    linear_extrude(height = 0.1)
                        rounded_hex_profile(head_radius_rear, edge_round);
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
    // Cup dish carved into the nose tip from the front
    // Positioned at the very tip, going inward
    translate([-nose_length, 0, 0])
        translate([0, 0, 0])
            sphere(r = cup_diameter / 2);
}

module leader_bore() {
    translate([-nose_length - 5, 0, 0])
        rotate([0, 90, 0])
            cylinder(h = head_length + nose_length + 5, d = leader_bore_diameter);
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
    // Jet channels through the body
    jet_entries = [
        [-nose_length + 2.5, jet_entry_offset, jet_entry_offset],
        [-nose_length + 2.5, -jet_entry_offset, jet_entry_offset],
        [-nose_length + 2.5, jet_entry_offset, -jet_entry_offset],
        [-nose_length + 2.5, -jet_entry_offset, -jet_entry_offset]
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

module jet_entrances() {
    // Cone-shaped entrances carved into the nose surface
    // These go from the nose tip inward
    jet_entry_locations = [
        [-nose_length, jet_entry_offset, jet_entry_offset],
        [-nose_length, -jet_entry_offset, jet_entry_offset],
        [-nose_length, jet_entry_offset, -jet_entry_offset],
        [-nose_length, -jet_entry_offset, -jet_entry_offset]
    ];
    
    for (i = [0:3]) {
        translate(jet_entry_locations[i])
            cylinder(h = jet_entrance_depth, r1 = jet_entrance_diameter / 2, r2 = 0, $fn = 16);
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
    jet_entrances();
}
