shader_type spatial;
render_mode diffuse_burley;
uniform vec4 tint : source_color = vec4(0.24,0.29,0.27,1.0);
uniform bool floor_surface = false;
varying vec3 world;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) { vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment() {
 vec2 p=world.xz;
 float shade=1.0;
 if(floor_surface) {
   vec2 board=vec2(p.x*1.65,p.y*.42);
   board.y+=mod(floor(board.x),2.0)*.5;
   vec2 edge=min(fract(board),1.0-fract(board));
   shade=(.7+.3*hash(floor(board)))*smoothstep(.006,.025,min(edge.x,edge.y));
   shade*=.82+.12*noise(p*45.0)+.06*sin(p.y*33.0+sin(p.x*13.0)*3.0);
 } else {
   float horizontal=abs(world_normal.z)>.5?world.x:world.z;
   vec2 q=vec2(horizontal,world.y);
   float pattern=pow(abs(sin(q.x*9.0)*sin(q.y*7.0)),7.0);
   float damp=noise(q*1.3)*noise(q*4.0);
   float stain=noise(q*21.0)*.10-damp*.55;
   float crack=1.0-smoothstep(.008,.028,abs(sin(q.x*2.5+noise(q*3.0)*3.0+q.y*.3)));
   stain-=crack*.13;
   stain-=smoothstep(.4,.8,noise(vec2(q.x*3.0,q.y*.2)))*.17;
   shade=.85+stain-pattern*.23;
   if(mod(world.y+20.0,5.0)<1.15) shade*=.43+.10*step(.06,fract(horizontal*2.0));
 }
 ALBEDO=tint.rgb*max(shade,.12);
 ROUGHNESS=.92;
}
