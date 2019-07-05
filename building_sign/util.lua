building_sign.log = modutil.require("log").make_loggers()

function building_sign.out_of_limit(pos)
	if (pos.x>30927 or pos.x<-30912
	or  pos.y>30927 or pos.y<-30912
	or  pos.z>30927 or pos.z<-30912) then
		return true
	end
	return false
end

building_sign.S = modutil.require("translations")()
