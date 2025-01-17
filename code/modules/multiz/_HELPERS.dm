var/global/list/visible_spaces = list(/turf/simulated/open, /turf/simulated/floor/glass)

#define isopenspace(A) istype(A, /turf/simulated/open)
#define isvisiblespace(A) is_type_in_list(A, visible_spaces)
#define OPENSPACE_PLANE_START -23
#define OPENSPACE_PLANE_END -8
#define OPENSPACE_PLANE -25
#define OVER_OPENSPACE_PLANE -7

/turf/proc/is_space()
	return 0

/turf/space/is_space()
	return 1

// Called after turf replaces old one
/turf/proc/post_change()
	levelupdate()
	var/turf/simulated/open/T = GetAbove(src)
	if(istype(T))
		T.update_icon()


/proc/is_on_same_plane_or_station(var/z1, var/z2)
	if(z1 == z2)
		return 1
	if((z1 in map.zLevels) && (z2 in map.zLevels))
		return 1
	return 0

// BEGIN /VG/ CODE
/**
 * Z-Distance functions
 *
 * Because vanilla get_dist() only gets the max value of either x or y and not z for some reason, thanks BYOND!
 *
 * Euclidean follows suit for the proper formula
 */
/proc/get_z_dist(atom/Loc1,atom/Loc2)
	var/dx = abs(Loc1.x - Loc2.x)
	var/dy = abs(Loc1.y - Loc2.y)
	var/dz = abs(Loc1.z - Loc2.z)

	if(!AreConnectedZLevels(Loc1.z, Loc2.z))
		return INFINITY

	return max(dx,dy,dz)

/proc/get_z_dist_euclidian(atom/Loc1, atom/Loc2)
	var/dx = Loc1.x - Loc2.x
	var/dy = Loc1.y - Loc2.y
	var/dz = Loc1.z - Loc2.z

	if(!AreConnectedZLevels(Loc1.z, Loc2.z))
		return INFINITY

	return sqrt(dx**2 + dy**2 + dz**2)

/**
 * Get Distance, Squared
 *
 * Because sqrt is slow, this returns the z distance squared, which skips the sqrt step.
 *
 * Use to compare distances. Used in component mobs.
 */
/proc/get_z_dist_squared(var/atom/a, var/atom/b)
	if(!AreConnectedZLevels(a.z, b.z))
		return INFINITY

	return ((b.x-a.x)**2) + ((b.y-a.y)**2) + ((b.z-a.z)**2)

/proc/multi_z_spiral_block(var/turf/epicenter,var/max_range,var/inward=0,var/draw_red=0,var/cube=1)
	var/list/spiraled_turfs = list()
	var/turf/upturf = epicenter
	var/turf/downturf = epicenter
	if(inward)
		var/upcount = 1
		var/downcount = 1
		for(var/i = 1, i < max_range, i++)
			if(HasAbove(upturf.z))
				upturf = GetAbove(upturf)
				upcount++
			if(HasBelow(downturf.z))
				downturf = GetBelow(downturf)
				downcount++
		for(var/i = 1, i < max_range, i++)
			if(GetBelow(upturf) != epicenter)
				upturf = GetBelow(upturf)
				spiraled_turfs += spiral_block(upturf, cube ? max_range : i + (max_range - upcount), inward, draw_red)
				log_debug("Spiralling block of size [cube ? max_range : i + (max_range - upcount)] in [upturf.loc.name] ([upturf.x],[upturf.y],[upturf.z])")
			if(GetAbove(upturf) != epicenter)
				downturf = GetAbove(downturf)
				spiraled_turfs += spiral_block(downturf, cube ? max_range : i + (max_range - downcount), inward, draw_red)
				log_debug("Spiralling block of size [cube ? max_range : i + (max_range - downcount)] in [downturf.loc.name] ([downturf.x],[downturf.y],[downturf.z])")
		log_debug("Spiralling block of size [max_range] in [epicenter.loc.name] ([epicenter.x],[epicenter.y],[epicenter.z])")
		spiraled_turfs += spiral_block(epicenter,max_range,inward,draw_red)
	else
		log_debug("Spiralling block of size [max_range] in [epicenter.loc.name] ([epicenter.x],[epicenter.y],[epicenter.z])")
		spiraled_turfs += spiral_block(epicenter,max_range,inward,draw_red)
		for(var/i = 1, i < max_range, i++)
			if(HasAbove(upturf.z))
				upturf = GetAbove(upturf)
				log_debug("Spiralling block of size [cube ? max_range : i + (max_range - i)] in [upturf.loc.name] ([upturf.x],[upturf.y],[upturf.z])")
				spiraled_turfs += spiral_block(upturf, cube ? max_range : max_range - i, inward, draw_red)
			if(HasBelow(downturf.z))
				downturf = GetBelow(downturf)
				log_debug("Spiralling block of size [cube ? max_range : i + (max_range - i)] in [downturf.loc.name] ([downturf.x],[downturf.y],[downturf.z])")
				spiraled_turfs += spiral_block(downturf, cube ? max_range : max_range - i, inward, draw_red)

	return spiraled_turfs

/client/proc/check_multi_z_spiral()
	set name = "Check Multi-Z Spiral Block"
	set category = "Debug"

	var/turf/epicenter = get_turf(usr)
	var/max_range = input("Set the max range") as num
	var/inward_txt = alert("Which way?","Spiral Block", "Inward","Outward")
	var/inward = inward_txt == "Inward" ? 1 : 0
	var/shape_txt = alert("What shape?","Spiral Block", "Cube","Octahedron")
	var/shape = shape_txt == "Cube" ? 1 : 0
	multi_z_spiral_block(epicenter,max_range,inward,1,shape)

// Halves above and below, as per suggestion by deity on how to handle multi-z explosions
/proc/explosion_destroy_multi_z(turf/epicenter, turf/offcenter, const/devastation_range, const/heavy_impact_range, const/light_impact_range, const/flash_range, var/explosion_time)
	if(HasAbove(offcenter.z) && (devastation_range >= 1 || heavy_impact_range >= 1 || light_impact_range >= 1 || flash_range >= 1))
		var/turf/upcenter = GetAbove(offcenter)
		if(upcenter.z > epicenter.z)
			explosion_destroy(epicenter, upcenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, explosion_time)
	if(HasBelow(offcenter.z) && (devastation_range >= 1 || heavy_impact_range >= 1 || light_impact_range >= 1 || flash_range >= 1))
		var/turf/downcenter = GetBelow(offcenter)
		if(downcenter.z < epicenter.z)
			explosion_destroy(epicenter, downcenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, explosion_time)