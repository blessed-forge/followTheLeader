--[[

--]]

followTheLeader = {}


function followTheLeader.Initialize()
	followTheLeader.leaderName = L""
	-- CREATE WINDOW
	CreateWindow ("followTheLeaderWindow", true)
	LayoutEditor.RegisterWindow( "followTheLeaderWindow",
                                L"followTheLeaderWindow",
                                L"followTheLeaderWindow",
                                true, false, --resizeble horizontally but not vertically (don't do vertical with buttons, trust me)
                                true, nil ) -- scaleable and something
	ButtonSetText ("followTheLeaderWindow", L"Follow the leader")

	-- saved variables
	if followTheLeader.settings == nil then
		followTheLeader.settings = {}
		followTheLeader.settings.version = "1.0.1"
		followTheLeader.settings.oneclickfollow = true --otherwise two clicks: target, then follow
		followTheLeader.settings.trackstate = false -- update the label with leaders name and targeting state, actually only useful if following is two-click
	end

	-- REGISTER EVENT HANDLERS (we probably don't need this many)
	RegisterEventHandler( SystemData.Events.GROUP_SET_LEADER, 					"followTheLeader.Update")
	--RegisterEventHandler( SystemData.Events.GROUP_UPDATED, 					"followTheLeader.Update")
    --RegisterEventHandler( SystemData.Events.GROUP_STATUS_UPDATED, 			"followTheLeader.Update")
	RegisterEventHandler( SystemData.Events.GROUP_PLAYER_ADDED, 				"followTheLeader.Update")
	RegisterEventHandler( SystemData.Events.PLAYER_GROUP_LEADER_STATUS_UPDATED, "followTheLeader.Update")
	RegisterEventHandler( SystemData.Events.GROUP_ACCEPT_INVITATION, 			"followTheLeader.Update")
	RegisterEventHandler( SystemData.Events.BATTLEGROUP_ACCEPT_INVITATION, 		"followTheLeader.Update")
	--RegisterEventHandler( SystemData.Events.BATTLEGROUP_UPDATED, 				"followTheLeader.Update")
	RegisterEventHandler( SystemData.Events.GROUP_SETTINGS_UPDATED, 			"followTheLeader.Update")
	--RegisterEventHandler( SystemData.Events.CHAT_TEXT_ARRIVED, 				"followTheLeader.OnChatText")

	if followTheLeader.settings.trackstate then
		followTheLeader.StateTrackingSet(true)
	end

	LibSlash.RegisterSlashCmd("followtheleader", function(msg) followTheLeader.slash(msg) end)
	TextLogAddEntry("Chat", 0, L"<icon00044> followTheLeader initialized.")
end


function followTheLeader.slash(msg)

	if msg == "oneclick" then
		followTheLeader.settings.oneclickfollow = not followTheLeader.settings.oneclickfollow
		TextLogAddEntry("Chat", 0, L"One click follow: "..towstring(tostring(followTheLeader.settings.oneclickfollow)))

	elseif msg == "trackstate" then
		followTheLeader.settings.trackstate = not followTheLeader.settings.trackstate
		followTheLeader.StateTrackingSet(followTheLeader.settings.trackstate)
		TextLogAddEntry("Chat", 0, L"Track follow state: "..towstring(tostring(followTheLeader.settings.trackstate)))

	else
		TextLogAddEntry("Chat", 0, L"Follow the leader status:")
		TextLogAddEntry("Chat", 0, L"One click follow: "..towstring(tostring(followTheLeader.settings.oneclickfollow)))
		TextLogAddEntry("Chat", 0, L"Track follow state: "..towstring(tostring(followTheLeader.settings.trackstate)))
		TextLogAddEntry("Chat", 0, L"Optional parameters: oneclick, trackstate.")
	end
end


function followTheLeader.StateTrackingSet(enable)
	if enable then
		RegisterEventHandler( SystemData.Events.PLAYER_TARGET_UPDATED, "followTheLeader.OnTargetUpdated")
	else
		UnregisterEventHandler( SystemData.Events.PLAYER_TARGET_UPDATED, "followTheLeader.OnTargetUpdated")
	end
end


function followTheLeader.Update()
	-- decide if we need to show or hide the button, update leader name so that button targets the actual leader
	if (IsWarBandActive() and GameData.Player.isInScenario == false) then

		local leadname = followTheLeader.FixName(PartyUtils.GetWarbandLeader().name)
		if leadname == followTheLeader.FixName(GameData.Player.name) then
			followTheLeader.Hide()
		else
			followTheLeader.Show()
		end

		if leadname ~= followTheLeader.leaderName then
			TextLogAddEntry("Chat", SystemData.ChatLogFilters.BATTLEGROUP, L"<icon00044> Warband leader: "..leadname)
			followTheLeader.leaderName = leadname
			followTheLeader.SetLeaderName (followTheLeader.leaderName)
		end
	else
		followTheLeader.Hide()
	end
end


function followTheLeader.Show()
	WindowSetShowing("followTheLeaderWindow", true)
end


function followTheLeader.Hide()
	WindowSetShowing("followTheLeaderWindow", false)
end


function followTheLeader.SetLeaderName (playerName)
	-- set button to target leader on user click (can't just target it through script)
	followTheLeader.leaderName = playerName
	WindowSetGameActionData ("followTheLeaderWindow", GameData.PlayerActions.SET_TARGET, 0, followTheLeader.leaderName or L"")
end

function followTheLeader.OnTargetUpdated()
	followTheLeader.TrackState()
end


function followTheLeader.TrackState()
	-- update targeting state ('target John', 'follow John')
	TargetInfo:UpdateFromClient()
	local targetname = followTheLeader.FixName(TargetInfo:UnitName("selffriendlytarget"))
	--d(targetname)

	local targetIsLeader = (targetname == followTheLeader.leaderName) and (targetname ~= followTheLeader.FixName(GameData.Player.name)) and targetname ~= L"" and targetname

	if targetIsLeader or followTheLeader.settings.oneclickfollow then
		ButtonSetText ("followTheLeaderWindow", L"Follow "..followTheLeader.leaderName)
	else
		ButtonSetText ("followTheLeaderWindow", L"Target "..followTheLeader.leaderName)
	end

end


function followTheLeader.OnMouseOver()
	-- just a tooltip
	local anchor = { Point="right",  RelativeTo=SystemData.ActiveWindow.name, RelativePoint="left", XOffset=20, YOffset=0 }
	Tooltips.CreateTextOnlyTooltip( SystemData.ActiveWindow.name )
    Tooltips.SetTooltipText( 1, 1, L"LClick to target/follow the leader.\nRClick to follow current target.")
    Tooltips.Finalize();
    Tooltips.AnchorTooltip( anchor )
end

function followTheLeader.OnLButtonUp()
	-- update leader name
	followTheLeader.Update()

	-- get newest target info if we want to follow it in one click (not just target)
	if followTheLeader.settings.oneclickfollow then
		TargetInfo:UpdateFromClient()
	end

	--get target and if target is the leader, follow it
	local targetname = followTheLeader.FixName(TargetInfo:UnitName("selffriendlytarget"))
	local targetIsLeader = (targetname == followTheLeader.leaderName) and (targetname ~= followTheLeader.FixName(GameData.Player.name)) and targetname ~= L""
	if targetIsLeader then
		SendChatText( L"/follow ", L"" )
		followTheLeader.leaderIsTargeted = true
	end
end


function followTheLeader.OnRButtonUp()
	-- follow current target
	local targetname = followTheLeader.FixName(TargetInfo:UnitName("selffriendlytarget"))
	if (targetname ~= followTheLeader.FixName(GameData.Player.name)) and targetname ~= L"" then
		SendChatText( L"/follow ", L"" )
	end
end


function followTheLeader.FixName (str)
	-- is needed because target TargetInfo:UnitName(...) may not match PartyUtils.GetWarbandLeader().name even when they must be the same

	if (str == nil) then return nil end

	local str = str
	local pos = str:find (L"^", 1, true)
	if (pos) then str = str:sub (1, pos - 1) end

	return str
end
