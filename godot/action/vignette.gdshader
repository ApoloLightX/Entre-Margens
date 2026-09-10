shader_type canvas_item;
render_mode unshaded;
void fragment(){
	float edge=length((UV-vec2(.5))*vec2(1.35,1.1));
	float shade=smoothstep(.48,.88,edge)*.16;
	COLOR=vec4(.035,.075,.10,shade);
}
