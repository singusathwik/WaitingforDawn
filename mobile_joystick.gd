extends Control
var direction=Vector2.ZERO
func _draw():
 var c=size*.5
 draw_circle(c, size.x*.46, Color(.035,.04,.04,.48))
 draw_arc(c,size.x*.46,0,TAU,64,Color(.8,.78,.67,.45),2,true)
 draw_circle(c+direction*size.x*.26,size.x*.19,Color(.82,.8,.7,.45))
 draw_arc(c+direction*size.x*.26,size.x*.19,0,TAU,48,Color(.95,.91,.8,.8),2,true)
