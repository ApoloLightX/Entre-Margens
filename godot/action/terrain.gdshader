shader_type canvas_item;
render_mode unshaded;
uniform sampler2D paving : filter_nearest, repeat_disable;
uniform vec2 world_size = vec2(1500.0,1100.0);
uniform vec2 route[16];
uniform int route_count=0;
uniform bool outdoor=true;
uniform bool archive=false;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float line_distance(vec2 p,vec2 a,vec2 b){vec2 d=b-a;return length(p-a-d*clamp(dot(p-a,d)/max(dot(d,d),1.0),0.0,1.0));}
void fragment(){
	vec2 p=floor(UV*world_size/2.0)*2.0;
	float d=10000.0;
	for(int i=0;i<15;i++){if(i>=route_count-1){break;}d=min(d,line_distance(p,route[i],route[i+1]));}
	vec2 local=mod(p,48.0)/48.0;
	vec2 texpos=(vec2(80.0,0.0)+floor(local*16.0)+vec2(.5))/vec2(textureSize(paving,0));
	vec3 stone=texture(paving,texpos).rgb;
	float grit=hash(floor(p/4.0));
	vec3 snow=vec3(.66,.77,.81)+vec3((grit-.5)*.024);
	float edge=hash(floor(p/8.0))*12.0;
	float path=1.0-smoothstep(53.0+edge,83.0+edge,d);
	vec3 base=outdoor?mix(snow,stone*vec3(.88,.96,1.03),path):stone*vec3(.62,.75,.81);
	if(archive&&!outdoor){base=stone*vec3(.83,.78,.66);}
	if(!outdoor){
		vec2 grid=mod(p,336.0);
		float border=step(grid.x,3.0)+step(grid.y,3.0);
		base=mix(base,vec3(.32,.39,.41),min(border,1.0)*.4);
	}
	float variation=hash(floor(p/96.0));
	base*=.97+variation*.055;
	COLOR=vec4(base,1.0);
}
