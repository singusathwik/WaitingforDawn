shader_type spatial;
render_mode cull_disabled;
varying vec3 local;
void vertex(){
 local=VERTEX;
 float hem=1.0-clamp(VERTEX.y/1.9,0.0,1.0);
 VERTEX.x+=sin(TIME*1.7+VERTEX.y*4.0+VERTEX.z*8.0)*.035*hem;
 VERTEX.z+=sin(TIME*1.2+VERTEX.x*7.0)*.03*hem;
}
void fragment(){
 float folds=.5+.5*sin(UV.x*201.0+sin(UV.y*8.0)*.4);
 float grime=.5+.5*sin(local.x*31.0+local.y*9.0)*sin(local.z*37.0-local.y*17.0);
 ALBEDO=mix(vec3(.055,.062,.047),vec3(.22,.23,.18),folds*.65+grime*.2);
 ROUGHNESS=.98;
}
