shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform vec4 stain : source_color=vec4(.075,.068,.045,.78);
uniform float seed=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float n=noise(UV*9.0+seed)*.6+noise(UV*27.0+seed)*.3+noise(UV*71.0)*.1;
 float edge=1.0-smoothstep(.35,.96,length(p)+n*.42);
 ALBEDO=stain.rgb*(.65+n*.5);ROUGHNESS=.98;
 ALPHA=edge*smoothstep(.22,.65,n)*stain.a;
}
