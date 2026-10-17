shader_type spatial;
uniform vec4 tint : source_color=vec4(.46,.47,.39,1);
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 float mottling=n(UV*38.0)*.3+n(UV*110.0)*.12;
 float vein=1.0-smoothstep(.015,.045,abs(sin(UV.x*64.0+n(UV*18.0)*5.0+UV.y*11.0)));
 ALBEDO=tint.rgb*(.65+mottling-vein*.22);
 ROUGHNESS=.98;
}
