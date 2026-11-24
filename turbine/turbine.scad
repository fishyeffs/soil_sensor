// Conical helical Savonius-style VAWT: rotor + frame
// Set `part`, render (F6), export each STL separately.
part = "assembly"; // [assembly, rotor, frame_base, frame_top, shaft]
shaft_type = "printed"; // [printed, rod]  printed = lay-flat D-shaft part; rod = buy 8 mm rod

$fn = 96;

// ---- Rotor ----
h       = 150;           // rotor height
r_bot   = 60;            // rotor radius at base
r_top   = 30;            // rotor radius at top
blades  = 3;
twist   = 360 / blades;  // each blade sweeps one sector, so some blade always faces the wind
t       = 1.5;           // blade thickness at base (scales to t*r_top/r_bot at the top)
r_inner = 10;            // blade root radius; keeps the axis clear for the shaft
plate_t = 2;             // end plate thickness
shaft_d = 8;             // rod: printed undersize -> press fit on 8 mm rod

// ---- Frame ----
clear   = 4;             // radial gap rotor <-> struts
gap     = 3;             // axial gap rotor <-> hubs
struts  = 4;
strut_d = 6;
ring_w  = 6;
ring_h  = 5;
brg_od  = 22;            // 608 bearing
brg_h   = 7;
hub_h   = brg_h + 1.5;

z_b = -gap - hub_h;
z_t = h + gap;

// ---- Printed shaft (shaft_type = "printed") ----
// Printed lying flat so layers run along the shaft (strong in bending).
// Top and bottom are flattened so it sits on the bed with no supports; the round
// arcs left over (~230 deg) still centre it in the 608s. The rotor bore uses the
// same flats, so the rotor is keyed to the shaft and can't slip.
shaft_fit  = 0.05;       // undersize vs 8 mm bearing bore; tune in 0.05 steps for a snug push fit
shaft_flat = 0.6;        // depth of each flat
bore_clear = 0.3;        // rotor bore clearance over the shaft (slide-on, flats carry torque)
collar_d   = 11.5;       // integral spacer under the rotor; stays inside the 608 inner race
flat_h     = shaft_d - 2 * shaft_flat;

// circle with flats at +/-X (they become top/bottom when the shaft is laid flat)
module flat_circle(d) intersection() { circle(d = d); square([flat_h, d + 1], center = true); }

module shaft() {
    translate([0, 0, z_b]) linear_extrude(z_t + hub_h - z_b) flat_circle(shaft_d - shaft_fit);
    translate([0, 0, -gap]) linear_extrude(gap) flat_circle(collar_d);  // rotor rests on this
}

// strut centre radius at height z: follows the rotor's cone plus clearance
function rf(z) = r_bot + (r_top - r_bot) * z / h + clear + strut_d / 2;

// semicircular cup running from r_inner to r_bot
module blade_profile() {
    a = (r_bot - r_inner) / 2;
    translate([r_inner + a, 0]) intersection() {
        difference() { circle(a + t / 2); circle(a - t / 2); }
        translate([-a - t, 0]) square([2 * a + 2 * t, a + t]);
    }
}

module rotor() {
    difference() {
        union() {
            // twist = helix, scale = cone
            linear_extrude(h, twist = twist, scale = r_top / r_bot, slices = 150)
                for (i = [0 : blades - 1]) rotate(i * 360 / blades) blade_profile();
            cylinder(r = r_bot + t, h = plate_t);
            translate([0, 0, h - plate_t]) cylinder(r = r_top + t, h = plate_t);
        }
        translate([0, 0, -1]) linear_extrude(h + 2)
            if (shaft_type == "printed") flat_circle(shaft_d + bore_clear);
            else circle(d = shaft_d);
    }
}

// one frame level: ring + spokes + bearing hub. up = bearing pocket opens upward
module level(z, up) {
    r = rf(z);
    translate([0, 0, z]) difference() {
        union() {
            difference() {
                cylinder(r = r + ring_w / 2, h = ring_h);
                translate([0, 0, -1]) cylinder(r = r - ring_w / 2, h = ring_h + 2);
            }
            for (i = [0 : struts - 1]) rotate(i * 360 / struts)
                translate([0, -ring_w / 2, 0]) cube([r, ring_w, ring_h]);
            cylinder(d = brg_od + 6, h = hub_h);
        }
        translate([0, 0, up ? hub_h - brg_h : -0.01]) cylinder(d = brg_od + 0.2, h = brg_h + 0.02);
        translate([0, 0, -1]) cylinder(d = brg_od - 4, h = hub_h + 2);
        if (!up) for (i = [0 : struts - 1]) rotate(i * 360 / struts)   // strut pin sockets
            translate([r, 0, -1]) cylinder(d = strut_d / 2 + 0.3, h = 5);
    }
}

module frame_base() {
    level(z_b, true);
    for (i = [0 : struts - 1]) rotate(i * 360 / struts) {
        hull() {
            translate([rf(z_b), 0, z_b]) cylinder(d = strut_d, h = ring_h);
            translate([rf(z_t), 0, z_t - 0.01]) cylinder(d = strut_d, h = 0.01);
        }
        translate([rf(z_t), 0, z_t]) cylinder(d = strut_d / 2, h = 4);  // pin into top level
    }
}

if (part == "rotor")           rotor();
else if (part == "frame_base") frame_base();
else if (part == "frame_top")  translate([0, 0, -z_t]) level(z_t, false);
else if (part == "shaft")      translate([0, 0, flat_h / 2]) rotate([0, 90, 0]) shaft();  // lies on a flat
else {
    color("#004054") { frame_base(); level(z_t, false); }
    color("#FECF52") rotor();
    if (shaft_type == "printed") color("#465856") shaft();
}
