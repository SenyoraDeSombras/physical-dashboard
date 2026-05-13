// ==========================================
// GLOBAL PARAMETERS
// ==========================================

// 1. General dimensions
int_w = 140;
int_h = 75;
int_d = 65;
wall = 1.8; 
corner_radius = 12;
fn_val = 60;

steps_depth = 0.9;

// 2. Front panel and cover mounting
cover_thick = 2;
cover_screw_inset = 7; 
body_screw_d = 2.4;      // For 3mm self-tapping screw

// 3. Ammeter (Configurable mount)
ammeter_d = 52.5;
amm_mount_r = 35.6;      // DISTANCE FROM CENTER TO HOLE (configure here)
ammeter_pos = [35, 0];   // Offset of the entire device on the cover

// 4. Seven-segment display
disp_w = 51;
disp_h = 21;
disp_pos = [-35, 0];
disp_stand_d = 4.5;
disp_stand_h = 5;

// ARRAY OF DISPLAY STANDOFF POSITIONS (relative to cutout center)
disp_standoff_coords = [
    [-(disp_w/2 + disp_stand_d/2)-0, -(disp_h/2 + disp_stand_d/2)+1.5],
    [ (disp_w/2 + disp_stand_d/2)+4, -(disp_h/2 + disp_stand_d/2)+1.5],
    [-(disp_w/2 + disp_stand_d/2)-0,  (disp_h/2 + disp_stand_d/2)-1.5],
    [ (disp_w/2 + disp_stand_d/2)+4,  (disp_h/2 + disp_stand_d/2)-1.5]
];

// 5. PCB and USB
pcb_w = 68.5;
pcb_l = 54.5;
pcb_y_offset = 13.5;         // VERTICAL PCB POSITION (offset from the edge)
pcb_stand_h = 5;
usb_offset_from_bottom = 10; 

pcb_standoff_coords = [
    [3, 18], [53.5, 3], [3, 43.5], [53.5, 45]
];

// ==========================================
// HELPER MODULES
// ==========================================

module gusset(w, h, t) {
    polyhedron(
        points = [
            [0,0,0], [w,0,0], [0,t,0], [w,t,0], // Base
            [0,0,h], [0,t,h]                    // Top
        ],
        faces = [
            [0,1,3,2], [0,4,5,2], [1,3,5,4], [0,1,4], [2,3,5]
        ]
    );
}

// For better printing of PCB stands
module hyperboloid_half_horizontal(r_waist = 10, r_base = 20, h = 30, fn = 50) {
    r_w = max(r_waist, 0.001);
    
    // b is calculated assuming 'h' is the height from waist to the top
    b = h / sqrt(pow(r_base / r_w, 2) - 1);
    
    difference() {
        rotate_extrude($fn = 60) {
            polygon(
                concat(
                    // Center axis points (waist to top)
                    [ [0, 0], [0, -h] ],
                    
                    // Generate the curve from top down to waist (y=0)
                    [ for (i = [0 : fn]) 
                        let (
                            y = -1 * (h - (i/fn) * h),
                            x = r_w * sqrt(1 + pow(y/b, 2))
                        ) 
                        [x, y] 
                    ]
                )
            );
        }
        translate([0, 0, -1.8 - 3]) {
            cylinder(d = 3.2, h = 12, $fn = 32);
        }
    }
}

module standoff_through_all(h, hole_d, base_d, surface_thick) {
    difference() {
        union() {
            cylinder(d1 = base_d + 0.4, d2 = base_d, h = h, $fn = 32);
            rotate_extrude($fn = 52) { 
                translate([2, 0, 0]) // 1. Shift the circle from the center (torus radius)
                    circle(r = 0.009);
            }
        }
        translate([0, 0, -surface_thick - 1])
            cylinder(d = hole_d, h = h + surface_thick + 2, $fn = 32);
    }
}

module main_shape(w, h, d, r) {
    hull() {
        translate([r, r, 0]) cylinder(r = r, h = d, $fn = fn_val);
        translate([w - r, r, 0]) cylinder(r = r, h = d, $fn = fn_val);
        translate([r, h - r, 0]) cylinder(r = r, h = d, $fn = fn_val);
        translate([w - r, h - r, 0]) cylinder(r = r, h = d, $fn = fn_val);
    }
}

// ==========================================
// MAIN BODY
// ==========================================

module body() {
    ext_w = int_w + 2 * wall;
    ext_h = int_h + 2 * wall;
    ext_d = int_d + wall;

    difference() {
        difference() {
            main_shape(ext_w, ext_h, ext_d, corner_radius);
            for(x = [25, ext_w - 25], z = [20, ext_d - 20]) {
                translate([x, -5 + steps_depth, z]) 
                    rotate([-90, 0, 0]) 
                    cylinder(d = 10, h = 5, $fn = 32);
            }
        }
        
        translate([wall, wall, wall])
            main_shape(int_w, int_h, int_d + 10, corner_radius - wall);
            
        // USB hole (tied to pcb_y_offset)
        translate([ext_w - wall - 1, wall + pcb_y_offset + usb_offset_from_bottom, wall + pcb_stand_h + 2])
            cube([wall + 2, 12, 6]);

        for(x = [cover_screw_inset, ext_w - cover_screw_inset], 
            y = [cover_screw_inset, ext_h - cover_screw_inset]) {
            
            translate([x, y, ext_d - 15])
                cylinder(d = body_screw_d, h = 16, $fn = 32);
        }
        
        translate([ext_w - wall - pcb_w, wall + pcb_y_offset, wall]) {
            for(pos = pcb_standoff_coords) {
                translate([pos[0], pos[1], -wall - 1])
                    cylinder(d = 3.2, h = wall + 2, $fn = 32);
            }
        }
    }

    for(x = [cover_screw_inset, ext_w - cover_screw_inset], 
        y = [cover_screw_inset, ext_h - cover_screw_inset]) {
        
        translate([x, y, wall]) {
            difference() {
                cylinder(d = 8, h = ext_d - wall, $fn = 32);
                translate([0, 0, ext_d - wall - 15])
                    cylinder(d = body_screw_d, h = 16, $fn = 32);
            }
            
            dir_x = (x < ext_w/2) ? -1 : 1;
            dir_y = (y < ext_h/2) ? -1 : 1;
            
            translate([0, -2/2, 0]) 
                mirror([dir_x == 1 ? 1 : 0, 0, 0])
                gusset(8, 20, 2); 
            
            translate([-2/2, 0, 0])
                rotate([0, 0, 90])
                mirror([dir_y == 1 ? 1 : 0, 0, 0])
                gusset(8, 20, 2);
        }
    }

    // PCB standoffs (position depends on pcb_y_offset)
    translate([ext_w - wall - pcb_w, wall + pcb_y_offset, wall]) {
        for(pos = pcb_standoff_coords) {
            translate([pos[0], pos[1], 0]) {
                standoff_through_all(pcb_stand_h, 3.2, 4.5, wall);
            }
            translate([pos[0], pos[1], 2.8]) {
                hyperboloid_half_horizontal(r_waist = 2.2, r_base = 3.5, h = 3, fn = 50); 
            }
        }
    }
}

// ==========================================
// FRONT COVER
// ==========================================

module cover() {
    ext_w = int_w + 2 * wall;
    ext_h = int_h + 2 * wall;

    difference() {
        union() {
            main_shape(ext_w, ext_h, cover_thick, corner_radius);
            
            translate([ext_w/2 + disp_pos[0], ext_h/2 + disp_pos[1], cover_thick]) {
                for(pos = disp_standoff_coords) {
                    translate([pos[0], pos[1], 0]) 
                        standoff_through_all(disp_stand_h, 3.2, disp_stand_d, cover_thick);
                    translate([pos[0], pos[1], 2.8]) {
                        hyperboloid_half_horizontal(r_waist = 2.2, r_base = 3.5, h = 3, fn = 50); 
                    }
                }
            }
        }
        
        translate([ext_w/2 + ammeter_pos[0], ext_h/2 + ammeter_pos[1], -1]) {
            cylinder(d = ammeter_d, h = cover_thick + 2, $fn = fn_val);
            off = amm_mount_r * 0.7071;
            for(ix = [-1, 1], iy = [-1, 1])
                translate([ix * off, iy * off, 0])
                    cylinder(d = 3.8, h = cover_thick + 2, $fn = 32);
        }
        
        for(x = [cover_screw_inset, ext_w - cover_screw_inset], 
            y = [cover_screw_inset, ext_h - cover_screw_inset]) {
            
            translate([x, y, -1])
                cylinder(d = 3.4, h = cover_thick + 2, $fn = 32);
        }

        translate([ext_w/2 + disp_pos[0], ext_h/2 + disp_pos[1], -1]) {
            for(pos = disp_standoff_coords) {
                translate([pos[0], pos[1], 0])
                    cylinder(d = 3.2, h = cover_thick + 2, $fn = 32);
            }
        }
        
        translate([ext_w/2 + disp_pos[0] - disp_w/2, ext_h/2 + disp_pos[1] - disp_h/2, -1])
            cube([disp_w, disp_h, cover_thick + 8]);
    }
}

// ==========================================
// RENDER
// ==========================================

//body();

// translate([0, 0, int_d + 30]) 
     cover();
