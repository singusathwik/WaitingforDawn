shader_type canvas_item;
uniform float danger = 0.0;
void fragment() {
 vec2 p=UV*2.0-1.0;
 float edge=smoothstep(.35,1.35,length(p));
 COLOR=vec4(mix(vec3(.015,.025,.035),vec3(.36,.018,.008),danger),edge*(.25+danger*(.32+.09*sin(TIME*(5.0+danger*5.0)))));
}
