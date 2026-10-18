shader_type spatial;
uniform sampler2D dirt : source_color, filter_linear_mipmap, repeat_enable;
void fragment(){
 vec2 tiled=UV*vec2(24.0,18.0);
 vec2 cell=floor(tiled);vec2 f=fract(tiled);
 float checker=mod(cell.x+cell.y,2.0);
 float grout=step(.025,min(min(f.x,f.y),min(1.0-f.x,1.0-f.y)));
 float patina=texture(dirt,UV*4.0).r;
 vec3 tile=mix(vec3(.23,.24,.20),vec3(.34,.32,.25),checker)*mix(.55,1.0,patina);
 float crack=1.0-smoothstep(.004,.010,abs(f.y-(f.x*.43+.23)));
 float broken=step(.75,fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453));
 ALBEDO=mix(vec3(.045,.04,.03),tile,grout)*(1.0-crack*broken*.5);
 ROUGHNESS=.93;
}
