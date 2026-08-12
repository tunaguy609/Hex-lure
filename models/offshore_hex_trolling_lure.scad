$fn = 96;

head_length = 25.4;
head_diameter = 24;
head_radius = head_diameter / 2;
edge_round = 1.2;

nose_slant = 1.5;
nose_face_angle = atan(nose_slant / head_diameter);
cup_diameter = 18;
cup_depth = 5;
cup_radius = ((cup_diameter / 2) * (cup_diameter / 2) + cup_depth * cup_depth) / (2 * cup_depth);

collar_length = 24;
collar_section_length = collar_length / 2;
collar_max_diameter = 19;
collar_neck_diameter = 17;
skirt_bore_diameter = 16.25;
skirt_pocket_extension = 20;

leader_bore_diameter = 2.2;
jet_diameter = 2.2;

eye_diameter = 8;
eye_depth = 2.5;
eye_x = 14;
eye_surface_offset = 12.5;

jet_exit_x = 18;
jet_exit_y = 10.25;
jet_exit_z = 3.75;
jet_entry_offset = 4.25;

function hex_points(radius) = [
    for (i = [0:5]) [radius * cos(60 * i + 30), radius * sin(60 * i + 30)]
];

function nose_plane_x(z) = nose_slant / 2 - z * tan(nose_face_angle);

module rounded_hex_profile(radius, roundover) {
    offset(r = roundover)
        polygon(points = hex_points(radius - roundover));
}

module body_blank() {
    rotate([0, 0, 90])
        rotate([90, 0, 0])
        linear_extrude(height = head_length)
            rounded_hex_profile(head_radius, edge_round);
}

module front_trim() {
    translate([nose_slant / 2, 0, 0])
        rotate([0, nose_face_angle, 0])
            translate([-120, -120, -120])
                cube([120, 240, 240]);
}

module head_outer() {
    difference() {
        body_blank();
        front_trim();
    }
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
    translate([nose_slant / 2, 0, 0])
        rotate([0, nose_face_angle, 0])
            translate([cup_radius - cup_depth, 0, 0])
                sphere(r = cup_radius);
}

module leader_bore() {
    translate([-2, 0, 0])
        rotate([0, 90, 0])
            cylinder(h = head_length - skirt_pocket_extension + 2, d = leader_bore_diameter);
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
        [nose_plane_x(jet_entry_offset) + 0.2, jet_entry_offset, jet_entry_offset],
        [nose_plane_x(jet_entry_offset) + 0.2, -jet_entry_offset, jet_entry_offset],
        [nose_plane_x(-jet_entry_offset) + 0.2, jet_entry_offset, -jet_entry_offset],
        [nose_plane_x(-jet_entry_offset) + 0.2, -jet_entry_offset, -jet_entry_offset]
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
