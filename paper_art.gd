extends Control
func _draw():
 var rng=RandomNumberGenerator.new()
 rng.seed=2718
 for i in range(1800):
  var p=Vector2(rng.randf()*size.x,rng.randf()*size.y)
  draw_circle(p,rng.randf_range(.3,2.5),Color(.2,.1,.02,rng.randf_range(.01,.06)))
 for i in range(24):
  var p=Vector2(size.x*.87+rng.randf_range(-38,38),size.y*.18+rng.randf_range(-34,34))
  var contour=PackedVector2Array()
  var radius=rng.randf_range(2,18)
  for point in range(14):
   var angle=point*TAU/14
   contour.append(p+Vector2(cos(angle),sin(angle))*radius*rng.randf_range(.65,1.2))
  draw_colored_polygon(contour,Color(.27,.025,.013,.22))
 for i in range(35):
  var y=rng.randf()*size.y
  draw_line(Vector2(0,y),Vector2(rng.randf_range(8,28),y+4),Color(.2,.09,.02,.3),2)
