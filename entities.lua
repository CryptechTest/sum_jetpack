local S = minetest.get_translator(minetest.get_current_modname())


-- Staticdata handling because objects may want to be reloaded
function sum_jetpack.get_staticdata(self)
	local data = {
		_lastpos = self._lastpos,
		_age = self._age,
		_itemstack = self._itemstack,
	}
	return minetest.serialize(data)
end
function sum_jetpack.on_activate(self, staticdata, dtime_s)
	local data = minetest.deserialize(staticdata)
	if data then
		self._lastpos = data._lastpos
		self._age = data._age
		self._itemstack = data._itemstack
	end
	self._sounds = {
		engine = {
			time = 0,
			handle = nil
		},
	}
end


sum_jetpack.set_attach = function(self)
  if not self._driver then return end
	self._driver:set_attach(self.object, "",
		{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
end

sum_jetpack.attach_object = function(self, obj)
	self._driver = obj
	sum_jetpack.set_attach(self)

	-- local visual_size = get_visual_size(obj)
	local yaw = self.object:get_yaw()
	if obj and obj:is_player() then
		local name = obj:get_player_name()
		if mcl then mcl_player.player_attached[name] = true end
  end
  if self._driver then
    self.object:set_yaw(minetest.dir_to_yaw(self._driver:get_look_dir()))
  end
end

sum_jetpack.detach_object = function(self, change_pos)
	self:set_detach()
	-- self:set_properties({visual_size = get_visual_size(self)})
	if self:is_player() and mcl then
		mcl_player.player_attached[self:get_player_name()] = false
		mcl_player.player_set_animation(self, "stand" , 30)
	end
	if change_pos then
		self:set_pos(vector.add(self:get_pos(), vector.new(0, 0, 0)))
	end
end


local function sound_play(self, soundref, instance)
	instance.time = 0
	instance.handle = minetest.sound_play(soundref.name, {
		gain = soundref.gain,
		pitch = soundref.pitch,
		object = self.object,
	})
end

local function sound_stop(handle, fade)
	if not handle then return end
	if fade and minetest.sound_fade ~= nil then
		minetest.sound_fade(handle, 1, 0)
	else
		minetest.sound_stop(handle)
	end
end

local function sound_stop_all(self)
	if not self._sounds or type(self._sounds) ~= "table" then return end
	for _, sound in pairs(self._sounds) do
		sound_stop(sound.handle)
	end
end

local sound_list = {
	boost = {
		name = "sum_jetpack_flame",
		gain = 0.2,
		pitch = 0.6,
		duration = 3 + (3 * (1 - 0.6)), -- will stop the sound after this
	},
}

sum_jetpack.sound_timer_update = function(self, dtime)
	for _, sound in pairs(self._sounds) do
		if sound.handle then
			sound.time = sound.time + dtime
		end
	end
end


sum_jetpack.do_sounds = function(self)
	if self._sounds and self._sounds.engine then

		if not self._sounds.engine.handle and not self._disabled then
			sound_play(self, sound_list.boost, self._sounds.engine)
		elseif self._disabled or (self._sounds.engine.time > sound_list.boost.duration
		and self._sounds.engine.handle) then
			sound_stop(self._sounds.engine.handle)
			self._sounds.engine.handle = nil
		end

		if not self._driver and self._sounds.engine.handle then
			minetest.sound_stop(self._sounds.engine.handle)
			self._sounds.engine.handle = nil
		end
	else
		self._sounds.engine = {
			time = 0,
			handle = nil
		}
	end
end

sum_jetpack.drop_self = function(self)
	minetest.add_item(self.object:get_pos(), self._itemstack)
end


-- clean up
sum_jetpack.on_death = function(self, nothing)
	if self._itemstack then
		sum_jetpack.drop_self(self)
	end
  self.object:set_properties({
    physical = false
  })
	sound_stop_all(self)
  minetest.sound_play("sum_jetpack_fold", {
		gain = 1,
    object = self.object,
	})
  if self._driver then
    sum_jetpack.detach_object(self._driver, false)
  end
end


-- sum_jetpack

sum_jetpack.get_movement = function(self)
  if not self._driver or not self._driver:is_player() then return vector.new() end
  local ctrl = self._driver:get_player_control()
  if not ctrl then return vector.new() end

  local dir = self._driver:get_look_dir()

  local forward = 0
  local up = 0
  local right = 0
  if ctrl.up then
    forward = 1
  elseif ctrl.down then
    forward = -0.5
  end
  if ctrl.jump then
    up = 1
	elseif ctrl.aux1 then
		up = -1
  end
  if ctrl.left then
    right = -1
	elseif ctrl.right then
		right = 1
  end

  local v = vector.new()
  v = vector.multiply(dir, forward)

	if right ~= 0 then
		local yaw = minetest.dir_to_yaw(dir)
		yaw = yaw - (right * (math.pi / 2))
		yaw = minetest.yaw_to_dir(yaw)
		v = vector.add(v, yaw)
	end

	v.y = up
  return v
end

local gravity = -8
local move_speed = 20
sum_jetpack.on_step = function(self, dtime)
  if self._age < 100 then self._age = self._age + dtime end
	if self._age> 1 and self._itemstack then
		local wear = self._itemstack:get_wear()
		self._itemstack:set_wear(math.min(65534, wear + (65535 / 30) * dtime))
		if wear >= 65534 then
			self._disabled = true
		end
	end
	if self._sounds then
		sum_jetpack.sound_timer_update(self, dtime)
		sum_jetpack.do_sounds(self)
	end
  local p = self.object:get_pos()
  local node_floor = minetest.get_node(vector.offset(p, 0, -0.2, 0))
  local exit = (self._driver and self._driver:get_player_control().sneak)
            or (self._age > 1 and not self._driver)
  if exit then
    sum_jetpack.on_death(self, nil)
    self.object:remove()
    return false
  end

  if self._driver then
    self.object:set_yaw(minetest.dir_to_yaw(self._driver:get_look_dir()))
  end

  local a = vector.new()
	local move_mult = move_speed
	if self._disabled then move_mult = move_mult / 10
  a = vector.multiply(sum_jetpack.get_movement(self), move_speed)
  a = vector.add(a, vector.new(0, gravity, 0))
  if sum_air_currents and sum_air_currents.get_wind ~= nil then
    a = vector.add(a, vector.multiply(sum_air_currents.get_wind(p), 2))
  end
  self.object:set_acceleration(a)

  local vel = self.object:get_velocity()
  -- vel = vector.multiply(vel, 0.99)
  vel.x = vel.x * 0.99
  vel.y = vel.y * 0.98
  vel.z = vel.z * 0.99
  self.object:set_velocity(vel)
end

local cbsize = 0.3
local jetpack_ENTITY = {
	physical = false,
	timer = 0,
  -- backface_culling = false,
	visual = "mesh",
	mesh = "sum_jetpack.b3d",
	textures = {"sum_jetpack_texture.png"},
	visual_size = {x=1, y=1, z=1},
	collisionbox = {-cbsize, -0, -cbsize,
                   cbsize,  cbsize*2,  cbsize},
	pointable = false,

	get_staticdata = sum_jetpack.get_staticdata,
	on_activate = sum_jetpack.on_activate,
  on_step = sum_jetpack.on_step,
	_thrower = nil,
  _pilot = nil,
  _age = 0,
	_sounds = nil,
	_itemstack = nil,
	_disabled = false,

	_lastpos={},
}

minetest.register_entity("sum_jetpack:jetpack_ENTITY", jetpack_ENTITY)