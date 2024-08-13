

player.stand     = 0
player.walk      = 1
player.block     = 2
player.jump      = 3
player.fall      = 4
player.attack    = 5
player.attack_up = 6
player.hurt      = 7
player.dead      = 8
player.land      = 0


player.exit_animation  = $10
player.clear_animation = $ff-$10
player.lock_state      = $40
player.unlock_state    = $ff-$40

player.state.lo = player.state
player.position.x.lo = player.position.x
player.position.x.hi = player.position.x + 1

player.position.y.lo = player.position.y
player.position.y.hi = player.position.y + 1

