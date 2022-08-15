local S = minetest.get_translator(minetest.get_current_modname())

local mcl = minetest.get_modpath("mcl_core") ~= nil

-- Staticdata handling because objects may want to be reloaded
function sum_jetpack.get_staticdata(self)
	local itemstack = "sum_jetpack:jetpack"
	if self._itemstack then
		itemstack = self._itemstack:to_table()
	end
	local data = {
		_lastpos = self._lastpos,
		_age = self._age,
		_itemstack = itemstack,
	}
	return minetest.serialize(data)
end
function sum_jetpack.on_activate(self, staticdata, dtime_s)
	local data = minetest.deserialize(staticdata)
	if data then
		self._lastpos = data._lastpos
		self._age = data._age
		if self._itemstack == nil and data._itemstack ~= nil then
			self._itemstack = ItemStack(data._itemstack)
		end
	end
	self._sounds = {
		engine = {
			time = 0,
			handle = nil
		},
	}
	self._flags = {}
end


sum_jetpack.set_attach = function(self)
  if not self._driver then return end
	self.object:set_attach(self._driver, "",
		{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
end

sum_jetpack.attach_object = function(self, obj)
	self._driver = obj
	if self._driver and self._driver:is_player() then
		if playerphysics then
			playerphysics.add_physics_factor(self._driver, "gravity", "sum_jetpack:flight", 0)
			playerphysics.add_physics_factor(self._driver, "speed", "sum_jetpack:flight", 0)
		end
	end

	sum_jetpack.set_attach(self)

	local yaw = self.object:get_yaw()
  if self._driver then
    self.object:set_yaw(minetest.dir_to_yaw(self._driver:get_look_dir()))
  end
end

-- make sure the player doesn't get stuck
minetest.register_on_joinplayer(function(player)
	playerphysics.remove_physics_factor(player, "gravity", "sum_jetpack:flight")
	playerphysics.remove_physics_factor(player, "speed", "sum_jetpack:flight")
end)

sum_jetpack.detach_object = function(self, change_pos)
	if self._driver and self._driver:is_player() then
		if playerphysics then
			playerphysics.remove_physics_factor(self._driver, "gravity", "sum_jetpack:flight")
			playerphysics.remove_physics_factor(self._driver, "speed", "sum_jetpack:flight")
		end
	end
	self.object:set_detach()
	-- self:set_properties({visual_size = get_visual_size(self)})
	-- if self:is_player() and mcl then
	-- mcl_player.player_attached[self:get_player_name()] = false
	-- 	mcl_player.player_set_animation(self, "stand" , 30)
	-- end
	-- if change_pos then
	-- 	self:set_pos(vector.add(self:get_pos(), vector.new(0, 0, 0)))
	-- end
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
		pitch = 0.7,
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
	local drop = self._itemstack
	self._flags.removed = true
	if self._driver and self._driver:is_player() then
		if minetest.is_creative_enabled(self._driver:get_player_name()) then
			drop = nil
		else
			local inv = self._driver:get_inventory()
			drop = inv:add_item("main", drop)
		end
	end
	if drop then
		minetest.add_item(self.object:get_pos(), drop)
	end
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
	vel = self.object:get_velocity()
	vel = vector.multiply(vel, 0.8)
  if self._driver then
		minetest.after(0.01, function(vel, driver)
			driver:add_velocity(vel)
		end, vel, self._driver)
    sum_jetpack.detach_object(self, false)
  end
end


-- sum_jetpack

sum_jetpack.get_movement = function(self)
  if not self._driver or not self._driver:is_player() then return vector.new() end
  local ctrl = self._driver:get_player_control()
  if not ctrl then return vector.new() end

  local dir = self._driver:get_look_dir()
	dir.y = 0
	dir = vector.normalize(dir)

  local forward = 0
  local up = 0
  local right = 0
  if ctrl.up then
    forward = 1
  elseif ctrl.down then
    forward = -0.5
  end
  if ctrl.jump then
    up = 2
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

local particles = {
	flame = {
		texture = "sum_jetpack_particle_flame.png",
		vel = 30,
		time = 1,
		size = 0.7},
	smoke = {
		texture = "sum_jetpack_particle_smoke.png",
		vel = 8,
		time = 4,
		size = 1.3},
	spark = {
		texture = "sum_jetpack_particle_spark.png",
		vel = 40,
		time = 0.6,
		size = 1},
}
local exhaust = {
	dist = 0.6,
	yaw = 0.5,
}
sum_jetpack.do_particles = function(self, dtime)
	-- local rand = function(m, n)
	-- 	return (math.random()-0.5) * math.abs(m - n) + m
	-- end
	if not self._driver then return false end
	local wind_vel = vector.new()
	local p = self.object:get_pos()
	local v = self._driver:get_velocity()
	v = vector.multiply(v, 0.8)
	if sum_air_currents then
		sum_air_currents.get_wind(p)
	end
	for i=-1,0 do
		if i == 0 then i = 1 end
		local yaw = self.object:get_yaw() + (exhaust.yaw * i) + math.pi
		yaw = minetest.yaw_to_dir(yaw)
		yaw = vector.multiply(yaw, exhaust.dist)
		local ex = vector.add(p, yaw)
		ex.y = ex.y + 1
		for _, prt in pairs(particles) do
			minetest.add_particle({
				pos = ex,
				velocity = vector.add(v, vector.add( wind_vel, {x=0, y= prt.vel * -math.random(0.2*100,0.7*100)/100, z=0})),
				expirationtime = ((math.random() / 5) + 0.2) * prt.time,
				size = ((math.random())*4 + 0.1) * prt.size,
				collisiondetection = false,
				vertical = false,
				texture = prt.texture,
			})
		end
	end
end

local gravity = -1
local move_speed = 20
sum_jetpack.max_use_time = 30
sum_jetpack.wear_per_sec = 65535 / sum_jetpack.max_use_time
-- warn the player 5 sec before fuel runs out
sum_jetpack.wear_warn_level = (sum_jetpack.max_use_time - 5) * sum_jetpack.wear_per_sec

sum_jetpack.on_step = function(self, dtime)
  if self._age < 100 then self._age = self._age + dtime end
	if not self._flags.ready and self._age < 2 then return end
	if self._itemstack then
		local wear = self._itemstack:get_wear()
		self._itemstack:set_wear(math.min(65534, wear + (65535 / sum_jetpack.max_use_time) * dtime))
		self._fuel = sum_jetpack.max_use_time - (wear / sum_jetpack.wear_per_sec)
		if wear >= 65534 then
			self._disabled = true
			sum_jetpack.on_death(self, nil)
			self.object:remove()
			return false
		elseif wear >= sum_jetpack.wear_warn_level and (not self._flags.warn) then
			local warn_sound = minetest.sound_play("sum_jetpack_warn", {gain = 0.5, object = self.object})
			if warn_sound and minetest.sound_fade ~= nil then
				minetest.sound_fade(warn_sound, 0.1, 0) end
			self._flags.warn = true
		end
	end
	if self._sounds then
		sum_jetpack.sound_timer_update(self, dtime)
		sum_jetpack.do_sounds(self)
	end

	sum_jetpack.do_particles(self, dtime)

  local p = self.object:get_pos()
  local node_floor = minetest.get_node(vector.offset(p, 0, -0.2, 0))
  local exit = (self._driver and self._driver:get_player_control().sneak)
            or (self._age > 1 and not self._driver)
  if exit or (not self._driver) or (not self.object:get_attach()) then
    sum_jetpack.on_death(self, nil)
    self.object:remove()
    return false
  end

  if self._driver then
    self.object:set_yaw(minetest.dir_to_yaw(self._driver:get_look_dir()))
  end

  local a = vector.new()
	local move_mult = move_speed * dtime
	if self._disabled then move_mult = move_mult / 10 end

	local move_vect = sum_jetpack.get_movement(self)
  a = vector.multiply(move_vect, move_mult)
  -- a = vector.add(a, vector.new(0, gravity, 0))
  if sum_air_currents and sum_air_currents.get_wind ~= nil then
    a = vector.add(a, vector.multiply(sum_air_currents.get_wind(p), dtime * 0.1))
  end
	-- a = vector.add(a, 0, 30, 0)

  -- self._driver:add_velocity(a)

  local vel = self._driver:get_velocity()
  vel = vector.multiply(vel, -0.02)
	if vel.y > 0 then
		vel.y = vel.y * 2
	end
	vel = vector.add(a, vel)
  self._driver:add_velocity(vel)
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
                   cbsize,  cbsize*6,  cbsize},
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
	_flags = {},
	_fuel = sum_jetpack.max_use_time,

	_lastpos={},
}

minetest.register_entity("sum_jetpack:jetpack_ENTITY", jetpack_ENTITY)