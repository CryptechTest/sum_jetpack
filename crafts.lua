local S = minetest.get_translator(minetest.get_current_modname())

if true then
  local i = "default:steel_ingot"
  local s = "default:string"
	local l = "group:wool"
	if minetest.get_modpath("mcl_mobitems") then
		s = "mcl_mobitems:string"
		l = "mcl_mobitems:leather"
	end
  if minetest.get_modpath("mcl_core") then
    i = "mcl_core:iron_ingot"
  end
  local f = "sum_jetpack:jetpack_fuel"
	minetest.register_craft({
		output = "sum_jetpack:jetpack",
		recipe = {
			{l, f, l},
			{i, s, i},
			{i, l, i},
		},
	})
end

if true then
  local c = "default:coal_lump"
  if minetest.get_modpath("mcl_core") then
    c = "mcl_core:coal_lump"
  end

	local s = "default:coal_lump"
  if minetest.get_modpath("mcl_mobitems") then
    s = "mcl_mobitems:slimeball"
  elseif minetest.get_modpath("tnt") then
		s = "tnt:gunpowder"
	end

  minetest.register_craft({
    output = "sum_jetpack:jetpack_fuel 8",
    recipe = {
      {"",s,""},
      {c, c, c},
      {c, c, c}
    },
  })
  if minetest.get_modpath("mcl_core") then
    c = "mcl_core:charcoal_lump"
    minetest.register_craft({
      output = "sum_jetpack:jetpack_fuel 8",
      recipe = {
        {s,"", s},
        {c, c, c},
        {c, c, c}
      },
    })
  end
end

minetest.register_craft({
  output = "sum_jetpack:jetpack",
  recipe = {
    {"sum_jetpack:jetpack_fuel"},
    {"sum_jetpack:jetpack"}
  },
})