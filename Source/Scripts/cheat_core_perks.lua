-- ============================================================================
-- find_perk
-- ============================================================================
function cheat:find_perk(searchKey, returnAll, findAny)
  local tableName = "perk"
  Database.LoadTable(tableName)
  local tableInfo = Database.GetTableInfo(tableName)
  local rows = tableInfo.LineCount - 1
  local searchKeyUpper = cheat:toUpper(searchKey)
  local perk_id = nil
  local perk_name = nil
  local perks = {}
  
  for i=0,rows do
    local rowInfo = Database.GetTableLine(tableName, i)
    local found = false
    
    if not cheat:isBlank(searchKeyUpper) then
      if cheat:toUpper(rowInfo.perk_id) == searchKeyUpper then
        found = true
      end
      
      if string.find(cheat:toUpper(rowInfo.perk_name), searchKeyUpper, 1, true) then
        found = true
      end
    else
      found = true
    end
    
    if found and ( findAny or rowInfo.visibility == 2 )then
      perk_id = rowInfo.perk_id
      perk_name = rowInfo.perk_name
      
      if returnAll then
        local perk = {}
        perk.perk_id = perk_id
        perk.perk_name = perk_name
        table.insert(perks, perk)
      end
      
      cheat:logInfo("Found perk [%s] with id [%s].", tostring(perk_name), tostring(perk_id))
    end
  end
  
  if returnAll then
    cheat:logDebug("Returning [%s] perks.", tostring(#perks))
    return perks
  else
    cheat:logDebug("Returning perk [%s] with id [%s].", tostring(perk_name), tostring(perk_id))
    return perk_id, perk_name
  end
end

-- ============================================================================
-- cheat_find_perks
-- ============================================================================
cheat.cheat_find_perks_args = {
  token = function(args,name,showHelp) return cheat:argsGetOptional(args, name, nil, showHelp, "All or part of a the perk's name. Leave empty to list all perks.") end,
  any = function(args,name,showHelp) return cheat:argsGetOptionalBoolean(args, name, false, showHelp, "Whether to not filter out perks you can't select yourself") end
}

cheat:createCommand("cheat_find_perks", "cheat:cheat_find_perks(%line)", cheat.cheat_find_perks_args,
  "Finds all of the perks that match the given token.",
  "Show all perks", "cheat_find_perks token:",
  "Show all perks with 'hunt' in their name", "cheat_find_perks token:hunt")
function cheat:cheat_find_perks(line)
  local args = cheat:argsProcess(line, cheat.cheat_find_perks_args)
  local token, tokenErr = cheat:argsGet(args, 'token', nil)
  local any = cheat:argsGet(args,'any')
  if not tokenErr then
    cheat:find_perk(token,nil,any)
    return true
  end
  return false
end

-- ============================================================================
-- cheat_add_perk
-- ============================================================================
cheat.cheat_add_perk_args = {
  id = function(args,name,showHelp) return cheat:argsGetRequired(args, name, showHelp, "The perk ID or all or part of a the perk's name. Uses last match from cheat_find_perks.") end,
  any = function(args,name,showHelp) return cheat:argsGetOptionalBoolean(args, name, false, showHelp, "Whether to not filter out perks you can't select yourself") end
}

cheat:createCommand("cheat_add_perk", "cheat:cheat_add_perk(%line)", cheat.cheat_add_perk_args,
  "Adds the given perk to the player.",
  "Adds the last perk with 'hunt' in its name", "cheat_add_perk id:hunt",
  "Adds the perk juggler perk by ID", "cheat_add_perk id:09a5f2a0-d59f-42c2-a80c-bec9ad7ca168",
  "Adds the perk general_speech perk by full name", "cheat_add_perk id:general_speech")
function cheat:cheat_add_perk(line)
  local args = cheat:argsProcess(line, cheat.cheat_add_perk_args)
  local id, idErr = cheat:argsGet(args, 'id')
  local any = cheat:argsGet(args,'any')
  if not idErr then
    local perk_id, perk_name = cheat:find_perk(id,nil,any)
    if not cheat:isBlank(perk_id) then
      player.soul:AddPerk(perk_id)
      cheat:logInfo("Added perk [%s] to player.", tostring(perk_name))
      return true
    else
      cheat:logError("Perk [%s] not found.", tostring(id))
    end
  end
  return false
end

-- ============================================================================
-- cheat_add_all_perks
-- ============================================================================
cheat.cheat_add_all_perks_args = {
  exclude = function(args,name,showHelp) return cheat:argsGetOptionalBoolean(args, name, false, showHelp, "If true then negative, test, and obsolete of perks are excluded.") end,
  any = function(args,name,showHelp) return cheat:argsGetOptionalBoolean(args, name, false, showHelp, "Whether to not filter out perks you can't select yourself") end
}

cheat:createCommand("cheat_add_all_perks", "cheat:cheat_add_all_perks(%line)", cheat.cheat_add_all_perks_args,
  "Adds all perks to the player.",
  "Add all perks", "cheat_add_all_perks exclude:true",
  "Add all perks including negative, test, and obsolete perks", "cheat_add_all_perks exclude:false")
function cheat:cheat_add_all_perks(line)
  local args = cheat:argsProcess(line, cheat.cheat_add_all_perks_args)
  local exclude, excludeErr = cheat:argsGet(args, 'exclude')
  local any = cheat:argsGet(args,'any')
  local gender = player.soul:GetGender()
  
  if gender ~= 2 then
    local excludes = {}
    excludes["80825cd9-7d7b-440f-aa57-75807e83aed9"] = true -- Always drunk
    excludes["fa299718-b1eb-4664-8769-25f82fb95de9"] = true -- LimitSprint
    excludes["12c75fff-d00d-4cb0-8c27-4a8e4838dc14"] = true -- test_dummy_perk
    excludes["519db599-76d4-4703-8c31-486fae00e473"] = true -- test_recipe
    excludes["a51bfbf1-f60b-40d2-ae3e-830127523862"] = true -- test_subperk
    excludes["e97c3ca4-04bc-4dfc-bd80-8002280c7c14"] = true -- test_metaperk
    excludes["775dcec-5dcd-48e7-810d-1fc97e4e203e"] = true -- Combo srt 04 cut mace OBSOLETE
    excludes["b74821b-9312-4e76-9c22-d2a38ba9dd06"] = true -- Combo srt 05 diagonalstrike mace OBSOLETE"
    excludes["b89f2c7-e5f3-415f-aec7-32d7655a94ba"] = true -- Combo srt 03 pommelstrike axe OBSOLETE"
    excludes["9ec2cf8-6e0b-4468-a7d1-7e538b676467"] = true -- Combo srt 05 diagonalstrike axe OBSOLETE"
    excludes["974b67f-0785-43ce-b51f-9779ecf42fb1"] = true -- Combo srt 03 pommelstrike shs OBSOLETE"
    excludes["574c37d-08af-4576-bcfd-29ccfa79e5ba"] = true -- Combo srt 03 pommelstrike mace OBSOLETE"
    excludes["8d9d23f-e293-4980-abd4-a3046b929771"] = true -- Combo srt 04 cut OBSOLETE"
    excludes["3f6c0eb-1b03-46ad-89f5-7eda9e4ab548"] = true -- Combo srt 04 cut axe OBSOLETE"
    
    -- charlitoti
    -- here is an extension of the excludes perk to exclude aswell the hardcore negative perks:
    excludes["37433f7b-9c2e-48e2-bce7-af8d34b403c8"] = true -- Nightmares
    excludes["5ef31fc4-244e-40ac-b088-03e5730ff5c1"] = true -- Claustrophobia
    excludes["6402905d-6cfa-4666-80bf-2a70b0b82bd1"] = true -- Haemophilia
    excludes["aa725966-98eb-4db2-8cd5-ad3d43b13f14"] = true -- Numbskull
    excludes["b9aa28f1-ccbb-4c0c-9718-c218f01d749b"] = true -- Consumption
    excludes["b59a2f39-faf4-4a1d-88c2-c059dadc6abb"] = true -- Shakes
    excludes["ce2fe289-4c26-45c0-803b-32627d288765"] = true -- Tapeworm
    excludes["d2105041-120b-4c06-8e61-1948a5fdf65d"] = true -- Somnambulant
    excludes["fbedb426-410c-4614-952a-1086b6f6554f"] = true -- Brittle Bones
    excludes["4d51ba41-2c10-4281-9308-fcfed1fe0276"] = true -- Woman in a Man's World
    
    -- WileCoyote68
    -- some more Hardcore related Perks
    excludes["1e53b07d-8012-44b1-ace6-3504558f04aa"] = true -- Hardcore Mode
    excludes["1e7c2255-b068-47a0-9447-4e0fe5205e8c"] = true -- Hardcore Mode Buff
    excludes["01c3b32a-5751-4c98-b6ab-258d02370382"] = true -- Hardcore Mode Constants
    excludes["305dd4f2-6923-42cb-a14d-2af07dff2863"] = true -- Revenant
    excludes["9a5842cb-6dc1-4602-a585-aa99bfc9eb16"] = true -- Insomniac
    excludes["d6916a36-f36e-4f7a-947b-d54ba84726f7"] = true -- Ascetic
    excludes["0f635b58-63e4-4db4-aa1a-5496d62e1a66"] = true -- Ascetic digestion
    excludes["871a05d0-8d1b-4abf-97ce-d8c496a220b5"] = true -- Ascetic overeat
    excludes["f1f439cd-7636-4060-8a8b-233153f7f685"] = true -- Thickblooded
    excludes["034494c7-db3d-47e0-a36f-ddd2aa9dee87"] = true -- Tutorial Injury
    excludes["16c67f0a-7770-416b-8bee-f9cbd8dd417a"] = true -- Tutorial Combat basic
    excludes["78d66139-9958-41cc-8148-8153f1a38efd"] = true -- Tutorial Horse
    excludes["9738139e-0957-4148-8585-8b71ef78ef30"] = true -- Tutorial Hardcore Mode
    excludes["f29a5eba-5c98-4779-9362-03dc5bfef316"] = true -- Tutorial Combat advanced
    
    local perks = cheat:find_perk(nil, true, any)
    for i,perk in pairs(perks) do
      if not exclude or not excludes[perk.perk_id] then
        player.soul:AddPerk(perk.perk_id)
        cheat:logInfo("Added perk [%s] to player.", tostring(perk.perk_name))
      else
        cheat:logInfo("Excluded perk [%s].", tostring(perk.perk_name))
      end
    end
    cheat:logInfo("All perks added.")
    return true
  else
    cheat:logError("You can't use this command when you're playing Thereza!")
  end
end

-- ============================================================================
-- cheat_remove_perk
-- ============================================================================
cheat.cheat_remove_perk_args = {
  id = function(args,name,showHelp) return cheat:argsGetRequired(args, name, showHelp, "The perk ID or all or part of a the perk's name. Uses last match from cheat_find_perks.") end,
  any = function(args,name,showHelp) return cheat:argsGetOptionalBoolean(args, name, false, showHelp, "Whether to not filter out perks you can't select yourself") end
}

cheat:createCommand("cheat_remove_perk", "cheat:cheat_remove_perk(%line)", cheat.cheat_remove_perk_args,
  "Removes the given perk from the player.",
  "Removes the last perk with 'hunt' in its name", "cheat_remove_perk id:hunt",
  "Removes the perk juggler by ID", "cheat_remove_perk id:09a5f2a0-d59f-42c2-a80c-bec9ad7ca168",
  "Removes the perk golden_tongue by full name.", "cheat_remove_perk id:golden_tongue")
function cheat:cheat_remove_perk(line)
  local args = cheat:argsProcess(line, cheat.cheat_remove_perk_args)
  local id, idErr = cheat:argsGet(args, 'id')
  local any = cheat:argsGet(args,'any')
  if not idErr then
    local perk_id, perk_name = cheat:find_perk(id,nil,any)
    if not cheat:isBlank(perk_id) then
      player.soul:RemovePerk(perk_id)
      cheat:logInfo("Removed perk [%s] from player.", tostring(perk_name))
      return true
    else
      cheat:logError("Perk [%s] not found.", tostring(id))
    end
  end
  return false
end

-- ============================================================================
-- cheat_remove_all_perks
-- ============================================================================
cheat:createCommand("cheat_remove_all_perks", "cheat:cheat_remove_all_perks()", nil,
  "Removes all perks from the player.",
  "Remove all perks", "cheat_remove_all_perks")
function cheat:cheat_remove_all_perks(line)
  local args = cheat:argsProcess(line, cheat.cheat_remove_perk_args)
  local any = cheat:argsGet(args,'any')
  local perks = cheat:find_perk(nil, true, any)
  for i,perk in pairs(perks) do
    player.soul:RemovePerk(perk.perk_id)
    cheat:logInfo("Removed perk [%s] from player.", tostring(perk.perk_name))
  end
  cheat:logInfo("All perks removed.")
  return true
end

-- ============================================================================
-- cheat_reset_perks
-- ============================================================================
cheat:createCommand("cheat_reset_perks", "cheat:cheat_reset_perks()", nil,
  "Resets all visible Perks.",
  "Reset all Perks", "cheat_reset_perks")
function cheat:cheat_reset_perks()
  cheat:cheat_add_buff("id:c8b0d038-a503-44cc-85a5-7f753a09eb6e")
  cheat:logInfo("All perks have been reset.")
  return true
end

-- ============================================================================
-- end
-- ============================================================================
cheat:logDebug("cheat_core_perks.lua loaded")