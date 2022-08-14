local S = minetest.get_translator(minetest.get_current_modname())

if true then
  local s = "default:string"
	local l = "group:wool"
	if minetest.get_modpath("mcl_mobitems") then
		s = "mcl_mobitems:string"
		l = "mcl_mobitems:leather"
	end
	minetest.register_craft({
		output = "sum_jetpack:parachute_bag",
		recipe = {
			{l, "", l},
			{l, s, l},
			{l, l, l},
		},
	})
end

if true then
  local c = "group:wool"
  if minetest.get_modpath("sum_airship") then
    c = "sum_airship:canvas_roll"
  end

	local s = "default:string"
	if minetest.get_modpath("mcl_mobitems") then
		s = "mcl_mobitems:string"
	end

  minetest.register_craft({
    output = "sum_jetpack:parachute_chute",
    recipe = {
      {c, c, c},
      {s, "", s}
    },
  })
end

minetest.register_craft({
  output = "sum_jetpack:parachute",
  recipe = {
    {"sum_jetpack:parachute_chute"},
    {"sum_jetpack:parachute_bag"}
  },
})