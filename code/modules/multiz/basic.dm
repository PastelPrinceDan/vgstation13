// If you add a more comprehensive system, just untick this file.
// WARNING: Only works for up to 17 z-levels!
var/z_levels = 0 // Each bit represents a connection between adjacent levels.  So the first bit means levels 1 and 2 are connected.

// If the height is more than 1, we mark all contained levels as connected.
/datum/map/proc/loadZLevelConnections(var/height,var/zPos)
	ASSERT(height <= zPos)
	// Due to the offsets of how connections are stored v.s. how z-levels are indexed, some magic number silliness happened.
	for(var/i = (zPos - height) to (zPos - 2))
		z_levels |= (1 << i)

// The storage of connections between adjacent levels means some bitwise magic is needed.
/proc/HasAbove(var/z)
	if(z >= world.maxz || z > 16 || z < 1)
		return 0
	return z_levels & (1 << (z - 1))

/proc/HasBelow(var/z)
	if(z > world.maxz || z > 17 || z < 2)
		return 0
	return z_levels & (1 << (z - 2))

// Thankfully, no bitwise magic is needed here.
/proc/GetAbove(var/atom/atom)
	var/turf/turf = get_turf(atom)
	if(!turf)
		return null
	return HasAbove(turf.z) ? get_step(turf, UP) : null

/proc/GetBelow(var/atom/atom)
	var/turf/turf = get_turf(atom)
	if(!turf)
		return null
	return HasBelow(turf.z) ? get_step(turf, DOWN) : null

/proc/GetConnectedZlevels(z)
	. = list(z)
	for(var/level = z, HasBelow(level), level--)
		. |= level-1
	for(var/level = z, HasAbove(level), level++)
		. |= level+1

/proc/AreConnectedZLevels(var/zA, var/zB)
	return zA == zB || (zB in GetConnectedZlevels(zA))

/proc/GetOpenConnectedZlevels(var/atom/atom)
	var/turf/turf = get_turf(atom)
	if (!turf)
		return list()
	. = list(turf.z)
	for(var/level = turf.z, HasBelow(level) && isvisiblespace(GetBelow(locate(turf.x,turf.y,level))), level--)
		. |= level-1
	for(var/level = turf.z, HasAbove(level) && isvisiblespace(GetAbove(locate(turf.x,turf.y,level))), level++)
		. |= level+1

/proc/AreOpenConnectedZLevels(var/zA, var/zB)
	return zA == zB || (zB in GetOpenConnectedZlevels(zA))

/proc/get_zstep(ref, dir)
	if(dir == UP)
		. = GetAbove(ref)
	else if (dir == DOWN)
		. = GetBelow(ref)
	else
		. = get_step(ref, dir)