shader_type spatial;
render_mode specular_schlick_ggx;
uniform sampler2D grime : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 paint : source_color = vec4(.12,.18,.14,1.0);
varying vec3 local_position;
void vertex(){local_position=VERTEX;}
void fragment(){
 float wear=texture(grime,UV*2.7).r;
 float edge_dirt=clamp((.75-local_position.y)*.6,0.0,.45);
 vec3 dusty=paint.rgb*mix(.68,1.12,wear);
 ALBEDO=mix(dusty,vec3(.13,.075,.035),edge_dirt*smoothstep(.25,.65,wear));
 ROUGHNESS=.6+wear*.3;
 METALLIC=.38;
}
