players_income = {}
payday = {}
local faktor = 500    -- defines how many nodes you have to dig until get a bluenote
local length_of_day = 1800   -- defines how long you must wait until get paid (in seconds)




minetest.register_chatcommand("payday", {
	params = "",
	description = "Shows you how much money you will get next payday",
	privs = {interact = true},
	func = function(playerName, param)
		if players_income[playerName] ~= nil then
			local balance = core.colorize('#ff0000', math.floor(1.5+(players_income[playerName]/faktor)))
			minetest.chat_send_player(playerName," >>> Next Payday you can expect "..balance.." Bluenotes")
			return
		end
	end
})


--
-- this function disables cheating by using money machines
--
local check_cheat = function(cheater,action)
	local name = cheater:get_player_name()
	local pos = cheater:getpos()
	local back = false
	if pos ~= nil then

		pos.y=pos.y+1.5
		
		local node = minetest.get_node(pos)
		if node.name == "pipeworks:nodebreaker_on" or node.name == "pipeworks:deployer_on" then
			back = true
			return back
		else

		if players_income[name] == nil then players_income[name] = 0 end
		  if action then
			players_income[name] = players_income[name] + 1    
		  else
			players_income[name] = players_income[name] + 1.5    -- placing a node is counted 0.5 more than digging a node
		  end		
				
		end	
	end
	return back
end

	

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime;
    if timer >= length_of_day then  
        timer = 0
        for _,player in ipairs(minetest.get_connected_players()) do
                local name = player:get_player_name()
                if players_income[name] == nil then players_income[name] = 0 end
		if payday[name] == nil then payday[name] = 0 end
		if not check_cheat(player) then
			payday[name] = 1     
		end
        end
    end
end)


earn_income = function(player,action)
	
    if not player then return end
    if check_cheat(player,action) then return end
    local name = player:get_player_name()
    local count = 0
    if payday[name] == nil then payday[name] = 0 end
    if payday[name] > 0 then
        count = math.floor(1.5+(players_income[name]/faktor)) 
        local inv = player:get_inventory()
        inv:add_item("main", {name="currency:minegeld_5", count=count})
	minetest.chat_send_player(name,"  --- PAYDAY --- you recieved "..count.." Bluenotes")
        payday[name] = 0
	players_income[name] = 0
	if count > 1 then
        	minetest.log("action", "[Currency] added "..count.." Bluenotes for "..name.." to inventory")
	end
    end
end

minetest.register_on_dignode(function(pos, oldnode, digger)
	
	earn_income(digger,true)

end)

minetest.register_on_placenode(function(pos, node, placer)
	earn_income(placer,false)
end)
