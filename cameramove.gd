extends Camera3D

var mapjson = JSON.new()
var mapstring
var map
var x0
var y0
var height
var width
var posx
var posy
var forward
var backwards
var right
var left
var currentTile
var forwardTile
var directionToCheck
var ftData
var tileToCheck
var startingPosition
var currentPosition
var correctBackMovementBehavior :bool = true
var moveforwardokay = false
var moveforwardcalled = false
enum directions {NORTH, EAST, SOUTH, WEST}
enum leftright {MOVELEFT, MOVERIGHT, MOVEBACK}
var currentDirection : directions
var askedDirection : directions
var mapPosition : Vector2i
var new_position : Vector3 = self.position
var new_rotation : Vector3
 
var walk_duration : float = 0.1
var rotate_duration : float = 0.1
var tile_pos : Vector2i:
	get:
		return Vector2i(floor(position.x), floor(position.z))
	set(value):
		tile_pos = value 

var is_ready : bool = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mapstring = (FileAccess.open("res://testmap1.json", FileAccess.READ).get_as_text())
	mapjson = JSON.parse_string(mapstring)
	x0 =  mapjson.regions[0].floors[0].tiles.bounds.x0
	y0 =  mapjson.regions[0].floors[0].tiles.bounds.y0
	width =  mapjson.regions[0].floors[0].tiles.bounds.width
	height =  mapjson.regions[0].floors[0].tiles.bounds.height
	map = mapjson.regions[0].floors[0].tiles.rows
	startingPosition = Vector3(0,0,0)
	currentPosition = Vector3(startingPosition)
	forward = transform.basis.z
	currentDirection = directions.NORTH
	mapPosition = Vector2i(0,0)
	#print(mapjson.regions[0].floors[0].tiles.rows)
	posx = mapPosition.x
	posy = mapPosition.y
	backwards = -transform.basis.z
	left = transform.basis.x
	right = -transform.basis.x
	askedDirection = currentDirection
	moveforwardokay = checkForward(currentDirection)
	#print(type_string(typeof(mapjson.regions[0].floors[0].tiles.rows[0])))
	pass # Replace with function body.

func _input(event):
	
	if event is InputEventKey:
		posx = mapPosition.x
		posy = mapPosition.y
		var mapy = getYColumn(posy)
		var mapx = getXPosition(posx, mapy)
		currentTile = mapy.tdata[mapx]
		#print(mapPosition)
		#makes sure a new movement wouldn't break something
		if(is_ready):
			if event.pressed and event.is_action_pressed("ui_up"):
				moveforwardcalled = true;
				askedDirection = currentDirection
				directionToCheck = forward
				moveforwardokay = checkForward(askedDirection)
			if event.pressed and event.is_action_pressed("ui_down"):	
				#checking if pressing back moves backwards (true) or rotates 180 degrees (false)
				if(correctBackMovementBehavior):
					moveforwardcalled = true;
					var newDirection = changeRotation(leftright.MOVEBACK, currentDirection)
					askedDirection = newDirection
					directionToCheck = backwards
					moveforwardokay = checkForward(askedDirection)
				else:
					transform = transform.orthonormalized()
					#rotate(Vector3(0,-1.0,0), PI/2)
					new_rotation = rotation
					new_rotation.y -= PI
					var tween : Tween = get_tree().create_tween()
					tween.tween_property(self, "rotation", new_rotation, rotate_duration)
					tween.connect("finished", tween_finished)
					currentDirection = changeRotation(leftright.MOVEBACK, currentDirection)
					is_ready = false
			if event.pressed and event.is_action_pressed("ui_strafe_left"):
				print("-----------------------------")
				print(left)
				var newDirection = changeRotation(leftright.MOVELEFT, currentDirection)
				print("-----------------------------")
				askedDirection = newDirection
				directionToCheck = left
				moveforwardcalled = true;
			if event.pressed and event.is_action_pressed("ui_strafe_left"):
				var newDirection = changeRotation(leftright.MOVERIGHT, currentDirection)
				askedDirection = newDirection
				directionToCheck = right
				moveforwardcalled = true;
			if event.pressed and event.is_action_pressed("ui_right"):
				transform = transform.orthonormalized()
				#rotate(Vector3(0,-1.0,0), PI/2)
				new_rotation = rotation
				new_rotation.y -= PI/2
				var tween : Tween = get_tree().create_tween()
				tween.tween_property(self, "rotation", new_rotation, rotate_duration)
				tween.connect("finished", tween_finished)
				currentDirection = changeRotation(leftright.MOVERIGHT, currentDirection)
				is_ready = false
			if event.pressed and event.is_action_pressed("ui_left"):
				transform = transform.orthonormalized()
				#rotate(Vector3(0,1.0,0), PI/2)
				new_rotation = rotation
				new_rotation.y += PI/2
				var tween : Tween = get_tree().create_tween()
				tween.tween_property(self, "rotation", new_rotation, rotate_duration)
				tween.connect("finished", tween_finished)
				currentDirection = changeRotation(leftright.MOVELEFT, currentDirection)
				is_ready = false
			#forward = transform.basis.z
			#backwards = -transform.basis.z
			#left = transform.basis.x
			#right = -transform.basis.x
			if(moveforwardcalled):
				moveforwardokay = checkForward(askedDirection)	
				if(moveforwardokay):
					new_position = transform.origin - directionToCheck
					var tween : Tween = get_tree().create_tween()
					tween.tween_property(self, "position", new_position, walk_duration)
					is_ready = false
					tween.connect("finished", tween_finished)
					var new_tile : Vector2i = Vector2i(floor(new_position.x), floor(new_position.z))
					emit_signal("enter_tile", new_tile)
					currentPosition -= directionToCheck
					mapPosition += updateMapPosition(askedDirection)
					
					directionToCheck = transform.basis.z
					askedDirection = currentDirection
					moveforwardokay = false
				moveforwardcalled = false
				
		#print(mapPosition)
		#print(forwardTile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass


func checkForward(givenDirection : directions) -> bool:
	var yy = getYColumn(mapPosition.y)
	var xx = getXPosition(mapPosition.x, yy)
	var xy = Vector2i(xx, yy.y)
	var facingVector = updateMapPosition(givenDirection)
	var yy2 = getYColumn(mapPosition.y+facingVector.y)
	var xx2 = getXPosition(mapPosition.x+facingVector.x, yy)
	var xy2 = Vector2(xx2, yy2.y)

	if(xy2.y == height || 
	xx2 == getRowLastPosition(yy2) || 
	xy2.y < y0 || 
	xy2.x < x0):
		forwardTile = null
		return false;
	#print(map[height-posy-1].tdata.size())
	forwardTile = xy2
	var yyy = getYColumn(forwardTile.y)
	ftData = getTile(forwardTile)
	#tileToCheck
	match givenDirection:
		directions.NORTH:
			if ftData.has("b"): 
				tileToCheck = ftData.b
			else:
				return true;
		directions.EAST:
			if currentTile.has("r"):
				tileToCheck = currentTile.r
			else:
				return true;
		directions.SOUTH:
			if currentTile.has("b"):
				tileToCheck = currentTile.b
			else:
				return true;
		directions.WEST:
			if ftData.has("r"):
				tileToCheck = ftData.r
			else:
				return true;
	#print(currentTile)
	#print(map[height-forwardTile.y-1])
	print(tileToCheck)
	match tileToCheck:
		0,2,4,29,33,null:
			return true
		_:
			return false

func changeRotation (direction: leftright, givenDirection: directions):
	if(direction == leftright.MOVELEFT):
		match givenDirection:
			directions.NORTH:
				return directions.WEST
			directions.WEST:
				return directions.SOUTH
			directions.SOUTH:
				return directions.EAST
			directions.EAST:
				return directions.NORTH
	if(direction == leftright.MOVERIGHT):
		match givenDirection:
			directions.NORTH:
				return directions.EAST
			directions.EAST:
				return directions.SOUTH
			directions.SOUTH:
				return directions.WEST
			directions.WEST:
				return directions.NORTH
	if(direction == leftright.MOVEBACK):
		match givenDirection:
			directions.NORTH:
				return directions.SOUTH
			directions.EAST:
				return directions.WEST
			directions.SOUTH:
				return directions.NORTH
			directions.WEST:
				return directions.EAST

func updateMapPosition(direction: directions):
	match direction:
			directions.NORTH:
				return Vector2i(0,1)
			directions.WEST:
				return Vector2i(-1,0)
			directions.SOUTH:
				return Vector2i(0,-1)
			directions.EAST:
				return Vector2i(1,0)

func tween_finished() -> void:
	forward = transform.basis.z
	backwards = -transform.basis.z
	left = -transform.basis.x
	right = transform.basis.x
	is_ready = true

# returns the information in a given tile
func getTile(coords : Vector2i):
	return getYColumn(coords.y).tdata[coords.x]




#returns the row where a given y coordinate would be after offsets
func getYColumn(yCoord : int):
	return map[height-yCoord-1+y0]

#returns the x position of a given x,y coordinate after offsets
func getXPosition(xCoord, yColumn):
	return  xCoord - x0 - yColumn.start
	
# returns the width of a given row	
func getRowLastPosition(yColumn):
	return yColumn.tdata.size()
