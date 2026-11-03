// ROVI v0.1 packaging study. Units: mm. Not production mounting geometry.
// Open in OpenSCAD; change part to "plate" or "upright" to export a fit-test STL.
// Colored boxes and wheels are placeholder keep-outs; replace from measured parts.
part="layout";
$fn=48;
plate_w=84; plate_l=124; plate_t=3;
module rounded(w,l,r,h){linear_extrude(h) hull() for(x=[-1,1],y=[-1,1])translate([x*(w/2-r),y*(l/2-r)]) circle(r=r);}
module slot(x,y,l=13,w=3){translate([x,y,-1])hull()for(d=[-1,1])translate([0,d*(l-w)/2,0]) cylinder(d=w,h=6);}
module plate(){difference(){rounded(plate_w,plate_l,7,plate_t);
for(x=[-30,30],y=[-32,-10,12,34])slot(x,y);
for(x=[-16,16])translate([x,47,-1])cylinder(d=3.4,h=6);
for(x=[-36,36],y=[-52,52])slot(x,y,9);}}
module upright(){difference(){union(){translate([-24,-7,0])cube([48,14,3]);translate([-24,3,3])cube([48,2.5,46]);}
for(x=[-16,16])translate([x,0,-1])cylinder(d=3.4,h=6);
for(x=[-19,19],z=[14,33])translate([x,8,z])rotate([90,0,0])cylinder(d=3.4,h=8);
translate([0,8,39])rotate([90,0,0])cylinder(d=10,h=8);}}
module box(p,s,c){color(c)translate(p)cube(s,center=true);}
if(part=="plate")plate();else if(part=="upright")upright();else{
color("silver")translate([0,0,9])plate();
translate([0,47,12])color("orange")upright();
for(i=[-1,1]){color("black")translate([i*48,0,16])rotate([0,90,0])cylinder(d=32,h=10,center=true);
box([i*27,0,18],[26,13,12],"gray");}
box([0,-26,24],[52,32,22],"green"); // provisional pack volume
box([0,17,22],[50,22,8],"blue"); // provisional control electronics
for(x=[-36,36],y=[-52,52])box([x,y,7],[8,9,4],"red");
color("gray")translate([0,-48,5])sphere(r=5);}
