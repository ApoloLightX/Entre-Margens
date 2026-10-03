"""Asset library for Passo da Mare Fria. Run in Blender 5.2 with --background --python."""
import bpy, math, random, sys, os, zipfile, base64
from pathlib import Path
from mathutils import Vector
random.seed(742)
OUT=Path(os.environ.get('ENTRE_MARGENS_ART', str(Path.home()/'Documents'/'EntreMargens3D'/'MareFria')))
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def mat(name,color,rough=.5,metal=0,emission=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 return m
ICE=mat('Ice_blue',(.16,.38,.48),.22,.25)
EDGE=mat('Ice_edge',(.52,.76,.82),.3,.12)
DARK=mat('Iron_weathered',(.055,.077,.09),.48,.72)
STEEL=mat('Steel_edge',(.16,.2,.23),.32,.78)
BRASS=mat('Copper_worn',(.32,.17,.075),.5,.6)
ROCK=mat('Cliff_stone',(.105,.145,.17),.92)
SNOW=mat('Snow_cap',(.67,.77,.79),.9)
WOOD=mat('Timber',(.17,.12,.08),.86)
LIGHT=mat('Heat_glass',(.95,.43,.14),.36,0,1.6)
CLOTH=mat('Woven_blue',(.08,.14,.19),.98)
ROOT=None

def parent(o,name,material):
 o.name=name
 if material:o.data.materials.append(material)
 if ROOT:o.parent=ROOT
 return o

def cube(name,pos,size,material,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);parent(o,name,material)
 if bevel:
  mod=o.modifiers.new('Rounded_edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
  mod=o.modifiers.new('Weighted_faces','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=mod.name)
 return o

def cyl(name,pos,radius,depth,material,vertices=16):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=pos);return parent(bpy.context.object,name,material)

def ball(name,pos,scale,material,sub=2):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=1,location=pos);o=bpy.context.object;o.scale=scale;parent(o,name,material)
 for p in o.data.polygons:p.use_smooth=True
 return o

def rod(name,a,b,r,material):
 a,b=Vector(a),Vector(b);o=cyl(name,(a+b)/2,r,(b-a).length,material,12);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o

def loft(name,rings,material,sides=12):
 vertices=[];faces=[]
 for center,rx,ry in rings:
  for i in range(sides):
   angle=2*math.pi*i/sides
   vertices.append((center[0]+rx*math.cos(angle),center[1]+ry*math.sin(angle),center[2]))
 for j in range(len(rings)-1):
  for i in range(sides):a=j*sides+i;b=j*sides+(i+1)%sides;faces.append((a,b,b+sides,a+sides))
 faces.append(tuple(reversed(range(sides))));faces.append(tuple((len(rings)-1)*sides+i for i in range(sides)))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);parent(o,name,material);return o

def start(name):
 global ROOT
 bpy.ops.object.select_all(action='DESELECT');ROOT=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(ROOT)

def descendants(root):
 result=[root]
 for o in root.children:result.extend(descendants(o))
 return result

def export(name):
 for o in descendants(ROOT):o.select_set(True)
 bpy.context.view_layer.objects.active=ROOT
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_materials='EXPORT')
 for o in descendants(ROOT):o.hide_set(True);o.select_set(False)
 print('ASSET',name,flush=True)

start('IceArm')
loft('Forearm',[((0,0,-.75),.16,.14),((0,0,-.55),.17,.14),((0,.005,-.3),.13,.105),((0,.008,-.08),.105,.075),((0,.005,.04),.14,.065),((0,0,.18),.17,.07),((0,0,.25),.155,.06)],ICE,16)
for i,(x,length) in enumerate([(-.117,.22),(-.039,.28),(.039,.265),(.117,.215)]):
 rings=[((x,0,.235),.037,.043),((x,.006,.29),.039,.043),((x,.018,.235+length*.5),.033,.035),((x,.04,.235+length*.78),.03,.031),((x,.06,.235+length),.015,.024)]
 finger=loft('Finger_'+str(i),rings,EDGE,10)
 for j in [0,1]:rod('Knuckle_seam', (x-.03,-.038,.3+j*.09),(x+.03,-.038,.3+j*.09),.005,ICE)
loft('Thumb',[((-.15,0,.05),.07,.055),((-.2,.012,.12),.062,.05),((-.245,.03,.19),.045,.04),((-.265,.06,.225),.025,.032)],EDGE,12)
for z,r in [(-.7,.174),(-.64,.172)]:cyl('Cuff', (0,0,z),r,.038,DARK,20)
for i in range(5):
 z=-.6+i*.11;x=random.uniform(-.08,.08)
 rod('Vein',(x,-.13,z),(x+.025,-.105,z+.09),.005,EDGE)
 for side in [-1,1]:
  o=ball('Ice_plate',(side*.12,0,z),(.048,.1,.11),EDGE,1);o.rotation_euler.z=side*.15
export('ice_arm')

start('Rock')
o=ball('Cliff_stone',(0,0,1),(1.4,1.05,2),ROCK,3)
for v in o.data.vertices:
 p=v.co;f=1+.11*math.sin(p.x*13+p.z*7)+.08*math.sin(p.y*17-p.z*11);v.co*=f
# Snow follows upper rock triangles, rather than a floating flat cap.
verts=[];faces=[]
for polygon in o.data.polygons:
 if polygon.center.z > .34:
  ids=[]
  for idx in polygon.vertices:
   p=o.data.vertices[idx].co.copy();p*=1.016;ids.append(len(verts));verts.append(tuple(p))
  faces.append(tuple(ids))
mesh=bpy.data.meshes.new('Snow_surface');mesh.from_pydata(verts,[],faces);cap=bpy.data.objects.new('Snow_cap',mesh);bpy.context.collection.objects.link(cap);cap.location=o.location;cap.scale=o.scale;parent(cap,'Snow_cap',SNOW)
export('cliff')

start('CrystalCluster')
for i in range(5):
 x=random.uniform(-.55,.55);y=random.uniform(-.4,.4);h=random.uniform(1.2,3)
 loft('Crystal', [((x,y,0),.2,.17),((x,y,h*.25),.28,.21),((x+.09,y,h*.8),.18,.15),((x+.1,y+.05,h),.003,.003)],ICE if i%2 else EDGE,6)
export('crystals')

start('Boardwalk')
for i in range(10):
 board=cube('Board',(0,-1.08+i*.24,0),(6.8,.23,.16),WOOD,.018)
 for x in [-3.05,3.05]:cyl('Nail',(x,-1.08+i*.24,.085),.012,.015,DARK,6)
for side in [-1,1]:
 x=side*3.4
 for y in [-1.1,1.1]:
  cube('Rail_post',(x,y,.7),(.13,.13,1.4),DARK)
  cube('Snow_post',(x,y,1.4),(.17,.17,.055),SNOW,.01)
 for z in [.65,1.25]:rod('Rail',(x,-1.2,z),(x,1.2,z),.04,DARK)
 cube('Snow_rail',(x,0,1.3),(.1,2.4,.04),SNOW,.01)
export('boardwalk')

start('Lantern')
cube('Base',(0,0,.06),(.35,.35,.12),DARK)
cube('Glass',(0,0,.3),(.22,.22,.38),LIGHT,.02)
for x in [-.145,.145]:
 for y in [-.145,.145]:rod('Frame',(x,y,.1),(x,y,.52),.022,DARK)
cube('Roof',(0,0,.55),(.4,.4,.1),DARK)
cube('Snow',(0,0,.61),(.39,.39,.035),SNOW,.015)
export('lantern')

start('Gate')
for side in [-1,1]:
 x=side*4.5
 for z,width in [(1,1.1),(3,1),(5,.9)]:
  cube('Pillar',(x,0,z),(width,1.4,2),ROCK,.12)
  cube('Band',(x,0,z+.9),(width+.12,1.52,.15),STEEL,.04)
 cube('Pillar_cap',(x,0,6.15),(1.5,1.8,.3),SNOW,.1)
 for z in [1.5,2.4,3.3,4.2]:cube('Carved_mark',(x,-.715,z),(.13,.045,.34),EDGE,.02)
for i in range(13):
 angle=math.pi*i/12
 x=4.5*math.cos(angle);z=4.7+1.6*math.sin(angle)
 o=cube('Arch_stone',(x,0,z),(.82,1.4,.8),ROCK,.09);o.rotation_euler.y=-(angle-math.pi/2)*.4
 cube('Arch_snow',(x,0,z+.42),(.8,1.45,.12),SNOW,.04)
export('gate')

start('Shelter')
cube('Foundation',(0,0,.3),(7,5,.6),ROCK,.09)
for x in [-3.3,3.3]:cube('Wall',(x,0,2),(.35,4.8,3.4),WOOD)
for y in [-2.3,2.3]:cube('Wall',(0,y,2),(6.6,.3,3.4),WOOD)
for x in [-2.1,2.1]:
 cube('Window_warm',(x,-2.47,2),(1.4,.055,1.4),LIGHT)
 for xx in [x-.75,x+.75]:cube('Window_frame',(xx,-2.52,2),(.1,.1,1.6),DARK)
 cube('Window_cross',(x,-2.53,2),(.075,.08,1.4),DARK)
cube('Door',(0,-2.49,1.5),(1.4,.09,2.4),DARK)
cube('Door_lamp',(0,-2.56,2.8),(.18,.09,.25),LIGHT)
for side in [-1,1]:
 roof=cube('Roof',(side*1.75,0,4.5),(3.9,5.8,.22),DARK,.03);roof.rotation_euler.y=side*math.radians(20)
 cap=cube('Roof_snow',(side*1.75,0,4.65),(3.9,5.8,.12),SNOW,.07);cap.rotation_euler.y=roof.rotation_euler.y
for x in [-3.5,3.5]:cube('Frame',(x,-2.7,2),(.24,.24,4),DARK)
for i in range(4):cube('Steps',(0,-2.9-i*.38,.3-i*.075),(2.4,.4,.15),WOOD)
cube('Chimney',(2,1,5),(.55,.55,1.8),ROCK,.04)
export('shelter')

start('Supplies')
cube('Crate',(0,0,.55),(1.3,1.1,1.1),WOOD,.04)
for z in [.2,.85]:
 for y in [-.57,.57]:cube('Band',(0,y,z),(1.36,.06,.1),DARK,.01)
for x in [-.63,.63]:cube('Corner',(x,-.57,.55),(.09,.09,1.15),STEEL)
ball('Bag',(.1,0,1.22),(.55,.4,.24),CLOTH,2)
export('supplies')

start('Sentinel')
cyl('Body',(0,0,1.1),.4,.75,DARK,24)
for z in [.8,1.05,1.35,1.5]:cyl('Body_ring',(0,0,z),.43,.065,BRASS,24)
ball('Head',(0,0,1.62),(.29,.26,.2),DARK,2)
for x in [-.11,.11]:cube('Eyes',(x,-.26,1.65),(.09,.045,.055),LIGHT,.012)
for x in [-.22,0,.22]:cube('Heat_slit',(x,-.39,1.15),(.09,.055,.36),LIGHT,.012)
for side in [-1,1]:
 for row in [-1,1]:
  x=side*.35;y=row*.23
  ball('Joint',(x,y,.85),(.14,.14,.14),STEEL)
  rod('Upper_leg',(x,y,.85),(side*.65,row*.38,.55),.1,DARK)
  ball('Knee',(side*.65,row*.38,.55),(.13,.13,.13),BRASS)
  rod('Lower_leg',(side*.65,row*.38,.55),(side*.78,row*.48,.15),.075,STEEL)
  cube('Foot',(side*.78,row*.48,.08),(.28,.34,.16),DARK)
  rod('Piston',(side*.42,row*.23,.8),(side*.74,row*.45,.21),.033,BRASS)
for angle in range(0,360,60):
 a=math.radians(angle);ball('Rivet',(.43*math.cos(a),.43*math.sin(a),1.34),(.026,.026,.026),STEEL,1)
cyl('Exhaust',(.2,.18,1.78),.07,.5,BRASS,12)
export('sentinel')

start('Sled')
for side in [-1,1]:
 x=side*.65
 rod('Runner',(x,-1.3,.13),(x,1.2,.13),.045,STEEL)
 rod('Tip',(x,-1.3,.13),(x,-1.65,.5),.045,STEEL)
for y in [-.8,0,.8]:cube('Slat',(0,y,.32),(1.5,.24,.12),WOOD)
for x in [-.5,.5]:rod('Upright',(x,.7,.3),(x,.7,.95),.04,DARK)
ball('Cargo',(0,.2,.62),(.6,.85,.35),CLOTH)
for y in [-.3,.5]:rod('Strap',(-.6,y,.8),(.6,y,.8),.025,BRASS)
export('sled')

bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'MareFria_Assets.blend'))
with zipfile.ZipFile(OUT/'models.zip','w',zipfile.ZIP_DEFLATED,9) as z:
 for p in OUT.glob('*.glb'):z.write(p,p.name)
payload=base64.b64encode((OUT/'models.zip').read_bytes()).decode()
(OUT/'models_payload.txt').write_text('BEGIN_PAYLOAD\n'+'\n'.join(payload[i:i+6000] for i in range(0,len(payload),6000))+'\nEND_PAYLOAD\n')
print('COMPLETE',str(OUT),len(payload),flush=True)
