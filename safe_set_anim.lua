

function sum_jetpack.safe_set_anim(player, anim_name)
  if player and player:is_player()
  and player.animations and player.animations[anim_name] then
    player:set_animation(player.animations[anim_name])
  else
    return false
  end
end