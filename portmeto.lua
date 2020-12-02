--------------------------
--       PortMeTo       --
--    Teleport Sing     --
-- Created by: MyTech78 --
--------------------------

-- register node
minetest.register_node("portmeto:teleport_sign", {
	description = "teleports the owner (only) to the configured location",
    drawtype = "nodebox",
	tiles = {"portmeto_teleport_sign.png"},
    inventory_image = "portmeto_teleport_sign.png",
    wield_image = "portmeto_teleport_sign.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    is_ground_content = false,
    walkable = false,
    node_box = {
        type = "wallmounted",
        wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
        wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
        wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
		},
    legacy_wallmounted = true,
    
    -- Creates a form when placing a node     
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
          meta:set_string("infotext", "Right Click To Configure")
          meta:set_string("formspec",
                    "size[5.5,4]"..
                    "real_coordinates[true]"..
                    "label[2,0.375;Coordinates]"..
                    "field[0.55,1.8;5,0.3;name; Name;]"..
                    "field[0.55,3;1.5,0.3;x; x;]"..
                    "field[2.25,3;1.5,0.3;y; y;]"..
                    "field[4,3;1.5,0.3;z; z;]"..
                    "button_exit[0.27,3.7;1.5,0.3;b_set;Set]"..
                    "button_exit[1.97,3.7;1.5,0.3;b_reset;Reset]"..
                    "button_exit[3.72,3.7;1.5,0.3;b_exit;Exit]")
        end,
    
    -- On right click collect info
    on_receive_fields = function(pos, formname, fields, sender)
        -- get the node metadata
        local meta = minetest.get_meta(pos)
        
     -- a few funtions to reduce the amount of code 
        -- function to log the action on the server console 
        local function send_log(log_text)
                minetest.log("action", sender:get_player_name()..
                " " .. log_text .. " " ..
                meta:get_string("owner").." at "..
                minetest.pos_to_string(pos))            
        end
        
        -- function to reset the node metadata
        local function meta_reset()
            meta:set_string("status", "not_configured")
            meta:set_string("tname", "")
            meta:set_string("infotext", "Teleport not configured " .. "(Belongs to "..
            meta:get_string("owner").. ")" )
        end
        
        -- function to set the node metadata
        local function meta_set()
            meta:set_string("status", "configured")
            meta:set_string("tname", fields.name)
            meta:set_int("x", fields.x)
            meta:set_int("y", fields.y)
            meta:set_int("z", fields.z)
            meta:set_string("infotext", "Teleport to "..
            meta:get_string("tname") ..  " (Belongs to "..
            meta:get_string("owner").. ")" )
        end
        
      -- logical part, well it felt logical to me!
        -- check if it's already configured (so only the owner will be able to change it)
        if meta:get_string("status") == "configured" then
            
                -- if the exit button was clicked (just exit)
            if fields.b_exit ~= nil then
                return
            
            -- if the reset button was clicked   
            elseif fields.b_reset ~= nil then

                -- check if it's the owner 
                if meta:get_string("owner") == sender:get_player_name() then
                    -- reset node metadata
                    meta_reset()
                else
                    -- if not the owner log the action on server console
                    send_log("tried to reset a teleport sign belonging to")
                end
            
            -- if the set button was clicked
            elseif fields.b_set ~= nil then
                
                -- check if it's the owner
                if meta:get_string("owner") == sender:get_player_name() then
                    -- set node metadata
                    meta_set()
                else
                    -- if not the owner log the action on server console
                    send_log("tried to configure a teleport sign belonging to")
                end
                
            end

        -- check if it was previously configured
        elseif meta:get_string("status") == "not_configured" then
            
            -- if the exit button is clicked (just exit)
            if fields.b_exit ~= nil then
                return
            
            -- if the reset button was clicked (clear node metadata)
            -- but it's already not configured, probably not needed! 
            -- needs revising but will leave it in for now
            elseif fields.b_reset ~= nil then
                
                    -- check if it's the owner
                if meta:get_string("owner") == sender:get_player_name() then
                    -- reset node metadata
                    meta_reset()
                else
                    -- if not the owner log the action on server console
                    send_log("tried to reset a teleport sign belonging to")
                end
             
            -- set button clicked (set metadata with fields, if its the owner)
            elseif fields.b_set ~= nil then
                
                    -- check if it's the owner
                if meta:get_string("owner") == sender:get_player_name() then
                    -- reset node metadata
                    meta_set()
                else
                    -- if not the owner log the action on server console
                    send_log("tried to configure a teleport sign belonging to")
                end
                
            end
        
        -- never configured (right-clicked for the first time). 
        -- then set node metadata with fields pluss the owner to protect the node from being changed by others. 
        else
                -- set the owner to lock it down
                meta:set_string("owner", sender:get_player_name())
                -- set node metadata
                meta_set()
        end
    end,
    
    -- on left click, check if it's the owner 
    -- and if configured teleport to the position  
    on_punch = function(pos, node, player, pointed_thing)
        local meta = minetest.get_meta(pos)
          if meta:get_string("tname") ~= "" then
            if meta:get_string("owner") == player:get_player_name() then
              local p={x=meta:get_int("x"), y=meta:get_int("y"), z=meta:get_int("z")}
              player:setpos(p)
            end  
          else
            return false
          end
      end,
    
    -- on left click, if not the owner just exit
    -- this will also allow the owner to break the node if not configured
    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
            if meta:get_string("owner") ~= player:get_player_name() then
                minetest.log("action", player:get_player_name()..
                " tried to dig a teleport sign belonging to "..
                meta:get_string("owner").." at "..
                minetest.pos_to_string(pos))
            return false
            else
            return true
            end
        end,
    
    -- configure node properties groups
    groups = {crumbly = 3},
    drop = "portmeto:teleport_sign"
  
})

-- register the recipe to create the node 
minetest.register_craft({
	output = 'portmeto:teleport_sign 1',
	recipe = {
		{'default:sign_wall_wood', 'default:steel_ingot', 'default:sign_wall_steel'},
		{'', 'default:stick', ''},
		{'', 'default:stick ', ''},
	}
})    