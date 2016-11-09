-- Author      : Haghala
-- Create Date : 13/10/2014
local addon = LibStub("AceAddon-3.0"):NewAddon("SliceAdmiral","AceConsole-3.0","AceEvent-3.0");
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("SliceAdmiral", true)
local S = LibStub("LibSmoothStatusBar-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
SliceAdmiralVer = GetAddOnMetadata("SliceAdmiral", "Version")
----------------------------------------------------------------------------------------------------

addon.opt = {
	Main = {name = "SliceAdmiral", type = "group", args = {}};
	ShowTimer = {name = "Timer Bars", type = "group", args = {}};
	Combo = {name = "Combo Points and Stats", type = "group", args = {}};
	Energy = {name = "Energy Bar", type = "group", args = {}};
	Sound = {name = "Sound Effects", type = "group", args = {}};
}

SADefault = {
	data = {
		Version = SliceAdmiralVer,
		UpdateInterval = 0.05,
		numStats = 3,		
	},
	Modules = {
		Main = {
			IsLocked = false,
			PadLatency = true,
			point = "TOPLEFT",
			xOfs = 100,
			yOfs = -150,
			Scale = 130,
			Width = 140,
			BarMargin = 1,
			Fade = 75,
			BarTexture = "BantoBar",
		},
		ShowTimer = {
			Options = {
				Barsup = true,
				SortBars = true,
				Dynamic = false,
				ShowDoTDmg = true,
				DoTCrits = true,
				BarTexture = "BantoBar",
				guileCount = false,
				BladeFlurry = false,
				ShowNames = false,
			},
			Colours = { 
				[980] = {r=0.36, g=0.1, b=0.776}, --Agony
				[63106] = {r=0.01, g=0.77, b=0.0}, --Siphon Life
				[146739] = {r=0.56, g=0.0, b=0.0}, --Corruption
				[205179] = {r=0.66, g=0.36, b=1.0}, --Phantom Singularity 
				[216708] = {r=0.1, g=0.6, b=0.8}, -- Deadwind Harvester 
				[233490] = {r=1.0, g=1.0, b=0.0}, -- Unstable Affliction 
			},
			Timers = {
				[980] = 5.4, --Agony
				[63106] = 4.5, --Siphon Life
				[146739] = 4.0, --Corruption
				[205179] = 6.0, --Phantom Singularity
				[216708] = 6.0, -- Deadwind Harvester
				[233490] = 6.0, -- Unstable Affliction
			},
			[980] = true, --Agony
			[63106] = true, --Siphon Life
			[146739] = true, --Corruption
			[205179] = true, -- Phantom Singluarity
			[216708] = true, -- Deadwind Harvester
			[233490] = false, -- Unstable Affliction
			},
		Combo = {
			PointShow = true,
			Texture = "Grid",
			AnticipationShow = true,
			ShowStatBar = true,
			HilightBuffed = false,
			CPColor = {r=0.7,g=0.2,b=0.96,a=1.0},
			AnColor = {r=1.0,g=0.15,b=0.2,a=1.0},
		},
		Energy  = {
			ShowEnergy = true,
			ShowComboText = true,
			AnticpationText = true,
			Energy1 = 25,
			Energy2 = 40,
			BarTexture = "BantoBar",
			EnergySound1 = "",
			EnergySound2 = "",
			EnergyTrans = 75,
			Color = {r=0.1, g=0.6, b=0.8},
			TextColor = { r=1.0, g=1.0, b=1.0, a=0.9},
			ComboTextColor = { r=1.0, g=1.0, b=1.0, a=0.8},
		},
		Sound = {
			[980] = {enabled=true, tick = "Shaker", alert = "BassDrum", tickStart=5.4, }, --Agony
			[63106] = {enabled=false, tick = "Cowbell", alert = "You Spin Me", tickStart=4.5, }, --Siphon Life
			[146739] = {enabled=false, tick = "Tambourine", alert = "Waaaah", tickStart=4.0, }, --Corruption
			[205179] = {enabled=false, tick="None", alter="None",tickStart=3.0}, -- Phantom Singularity
			[216708] = {enabled=false, tick="None", alter="None",tickStart=3.0}, -- Deadwind Harvester
			[233490] = {enabled=false, tick = "Ping", alert = "None", tickStart=3.0, }, --Unstable Affliction

			MasterVolume = false,
			OutOfCombat = true,
			none = "none",
		},
	},  
}

for k in pairs(SA_Spells) do
	if not SADefault.Modules.ShowTimer.Colours[k] then
		SADefault.Modules.ShowTimer.Colours[k] = {r=0,g=0,b=0,a=0}
		SADefault.Modules.ShowTimer.Timers[k] = 3.0
		SADefault.Modules.ShowTimer[k] = false
		SADefault.Modules.Sound[k] = {enabled=false, tick = "None", alert="None", tickStart=3.0 }
	end
end

SADefaults = {char = SADefault, realm = SADefault, profile = SADefault}
SAGlobals = {Version = SliceAdmiralVer}

SA_Data = {	
	guile = 0,
	sortPeriod = 0.2, -- Only sort bars every sortPeriod seconds
	lag = 0.1, -- not everyone plays with 50ms ping
	tNow = 0,
	sinister = true,
	BARS = { --TEH BARS
	["CP"] = {
		["obj"] = 0
	},
	["Stat"] = {
		["obj"] = 0,
	},
	["tmp"] = {
		["obj"] = 0,
	},
}
};

local scaleUI = 0
local widthUI = 0
local lastSort = 0

local UnitAffectingCombat = UnitAffectingCombat
local UnitAttackPower = UnitAttackPower
local UnitAttackSpeed = UnitAttackSpeed
local GetCritChance = GetCritChance
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitAura = UnitAura
local _,k,v,guileZero
local maxCP = 5 
local bfhits = {}
local soundBuffer = {}

local Sa_filter = {	["player"] = "PLAYER", 
["target"] = "PLAYER HARMFUL",
["pet"] = "PLAYER HARMFUL", };

local function Lsort(a,b)
	return floor(a["Expires"]) < floor(b["Expires"]); -- No need for decimals
end
local function idSort(a,b)
	return a["id"] < b["id"];
end

local function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function addon:SA_SetScale(NewScale)
	if (NewScale >= 50) then
		SA:SetScale ( NewScale / 100 );
		VTimerEnergy:SetScale ( NewScale / 100 );
		for k in pairs(SA_Data.BARS) do
			SA_Data.BARS[k]["obj"]:SetScale(NewScale/100);
		end
	end
end

function addon:SA_SetWidth(w)
	if (w >= 25) then
		VTimerEnergy:SetWidth(w);
		for k in pairs(SA_Data.BARS) do
			if not (k == "CP" or k == "Stat") then
				SA_Data.BARS[k]["obj"]:SetWidth(w-12);
			end
		end	
		if SAMod.Energy.ShowEnergy then
			VTimerEnergy:Show();
			local UnitPowerMax = UnitPowerMax("player",SPELL_POWER_ENERGY)
			if (UnitPowerMax == 0) then
				UnitPowerMax = 100;
			end
--			SA_Spark1:SetPoint("TOPLEFT", VTimerEnergy, "TOPLEFT", (SAMod.Energy.Energy1 / UnitPowerMax * w), 0);
	--		SA_Spark2:SetPoint("TOPLEFT", VTimerEnergy, "TOPLEFT", (SAMod.Energy.Energy2 / UnitPowerMax * w), 0);
		else
			VTimerEnergy:Hide();
		end
		addon:SA_UpdateCPWidths(w);
		addon:SA_UpdateStatWidths(w);

	end
end

function addon:RetextureBars(texture, object)
	if object == "Energy" then
		VTimerEnergy:SetStatusBarTexture(texture);
	end
	if object == "spells" then
		local bars =  SA_Data.BARS
		for k in pairs(bars) do
			if not (k == "CP" or k == "Stat") then
				bars[k]["obj"]:SetStatusBarTexture(texture);
			end	
		end
	end
	if object == "combo" then
		SA_Data.BARS["CP"]["obj"].combo:SetStatusBarTexture(texture);
		SA_Data.BARS["CP"]["obj"].anti:SetStatusBarTexture(texture);
	end
	if object == "stats" then		
		SA_Data.BARS["CP"]["obj"].bg:SetTexture(texture);
		SA_Data.BARS["Stat"]["obj"].bg:SetTexture(texture);
	end	
end

function addon:SA_BarTexture(object)
	if object == "Energy" then
		return LSM:Fetch("statusbar",SAMod.Energy.BarTexture)
	elseif object == "stats" then
		return LSM:Fetch("statusbar",SAMod.Main.BarTexture)
	elseif object == "spells" then
		return LSM:Fetch("statusbar",SAMod.ShowTimer.Options.BarTexture)
	elseif object == "combo" then
		return LSM:Fetch("statusbar",SAMod.Combo.Texture)
	else
		return LSM:Fetch("statusbar",SAMod.Main.BarTexture) ;
	end
end

function addon:SA_Sound(sound,bufferd)
	if not UnitAffectingCombat("player") and not SAMod.Sound.OutOfCombat then return end
	if not sound then return end
	soundBuffer[#soundBuffer+1] = sound;
	if bufferd then
		C_Timer.After(math.max(0.3, SA_Data.lag),addon.PlayBuffer)
	else
		addon:PlayBuffer()
	end
end

function addon:PlayBuffer()
	for k, v in pairs(soundBuffer) do
		if SAMod.Sound.MasterVolume then
			PlaySoundFile(v, "Master" );
		else
			PlaySoundFile(v);
		end
		table.remove(soundBuffer,k)
	end
end

function addon:SA_ChangeAnchor()
	local LastAnchor = SA;
	local FirstAnchor = SA;
	local offSetSize = SAMod.Main.BarMargin; -- other good values, -1, -2 
	local opt = SAMod.ShowTimer.Options
	local statsBar = SA_Data.BARS["Stat"]["obj"]
	local cpBar = SA_Data.BARS["CP"]["obj"]
	table.sort(SA_Data.BARORDER, idSort) --Fix for Roll the bone
	table.sort(SA_Data.BARORDER, Lsort)

	-- Stat bar goes first, because it's fucking awesome like that
	if SAMod.Combo.ShowStatBar then 	
		statsBar:ClearAllPoints();
		statsBar:SetPoint("TOPLEFT", LastAnchor, "BOTTOMLEFT", 0, -1 * offSetSize);
		FirstAnchor = statsBar;
		LastAnchor = statsBar;
	end

	--anchor CPs on stat bar if energy bar is hidden.
	if SAMod.Energy.ShowEnergy then	
		VTimerEnergy:ClearAllPoints()
		VTimerEnergy:SetPoint("TOPLEFT", LastAnchor, "BOTTOMLEFT", 0, -1 * offSetSize); 
		if not (FirstAnchor == statsBar) then FirstAnchor = VTimerEnergy end
		LastAnchor = VTimerEnergy;
	end

	-- CP Bar --
	if SAMod.Combo.PointShow then
		cpBar:ClearAllPoints(); --so it can move
		cpBar:SetPoint("TOPLEFT", LastAnchor, "BOTTOMLEFT", 0, -1 * offSetSize); --CP bar on bottom of Stat Bar
		if (FirstAnchor == SA) then FirstAnchor = cpBar end
		LastAnchor = cpBar
	end

	local tmp = SA_Data.BARS["tmp"]["obj"]
	if opt.Barsup then
		LastAnchor = FirstAnchor
		tmp:SetPoint("BOTTOMLEFT",LastAnchor,"TOPLEFT",12,-12);
	else
		tmp:SetPoint("TOPLEFT",LastAnchor,"BOTTOMLEFT",12,12);
	end
	LastAnchor = tmp 

	local function sortBar(SortBar)
		if (SortBar["Expires"] > SA_Data.tNow) and SortBar["obj"]:IsShown() then
			SortBar["obj"]:ClearAllPoints();
			if opt.Barsup then
				SortBar["obj"]:SetPoint("BOTTOMLEFT", LastAnchor, "TOPLEFT", 0, offSetSize); --bar on top
			else
				SortBar["obj"]:SetPoint("TOPLEFT", LastAnchor, "BOTTOMLEFT", 0, -1 * offSetSize);
			end
			LastAnchor = SortBar["obj"];
		end
	end

	for i = 1, #SA_Data.BARORDER do 
		sortBar(SA_Data.BARORDER[i])		
	end
	for i = 1, #SA_Data.TOPORDER do
		sortBar(SA_Data.TOPORDER[i])
	end 

end

function addon:PET_BATTLE_OPENING_START()
	SA:Hide();
end

function addon:PET_BATTLE_CLOSE()
	SA:Show();
end

function addon:PLAYER_ENTERING_WORLD(...)
	addon:UpdateTarget();
	addon:UpdateSoulShards();  
	addon:UpdateTormentedSouls();
end

function addon:PLAYER_TARGET_CHANGED(...)
	addon:UpdateTarget();
end

function addon:PLAYER_REGEN_DISABLED(...) --enter combat
	addon:SA_ResetBaseStats();
	UIFrameFadeIn(SA, 0.4, SA:GetAlpha(), 1.0);	

end

function addon:PLAYER_REGEN_ENABLED(...) --exit combat
	UIFrameFadeOut(SA, 0.4, SA:GetAlpha(), SAMod.Main.Fade/100)

end

function addon:UNIT_AURA(Time, arg1)	
	if SAMod.Combo.ShowStatBar then
		addon:SA_UpdateStats();
	end
	if arg1 == "player" then
		addon:UpdateTarget()
		addon:UpdateSoulShards();
		addon:UpdateTormentedSouls();
	end
end

function addon:UNIT_ATTACK_POWER(...)
	if SAMod.Combo.ShowStatBar then
		addon:SA_UpdateStats();
	end
end

function addon:UpdateBFText(what)
	if SAMod.ShowTimer.Options.BladeFlurry and SA_Data.BFActive then
		SA_Data.BARS["Stat"]["obj"].stats[3]:SetFormattedText(tablelength(bfhits));
	end	
	if not (what) then
		bfhits = {};
	end
end

local bfticker = C_Timer.NewTicker(10,addon.UpdateBFText)

function addon:UNIT_ATTACK_SPEED(...)
	if SAMod.Combo.ShowStatBar then
		addon:SA_UpdateStats();
	end	
	if SAMod.ShowTimer.Options.BladeFlurry and SA_Data.BFActive then
		if bfticker then bfticker:Cancel(); addon:UpdateBFText(true); end
		bfticker = C_Timer.NewTicker(math.max(UnitAttackSpeed("player") or 1), addon.UpdateBFText);
	end
end

function addon:UNIT_POWER_FREQUENT(Time,arg1,arg2)
	if not arg1 == "player" then return false end;
	if arg2 == "SOUL_SHARDS" then
		--addon:UpdateSoulShards();
		return true
	end
end

function addon:UNIT_MAXPOWER(...)
	local cpBar = SA_Data.BARS["CP"]["obj"]
	if SAMod.Energy.ShowEnergy then
		VTimerEnergy:SetMinMaxValues(0, 12);
		VTimerEnergy:SetValue(0)		
	end
	maxCP = UnitPowerMax("player",SPELL_POWER_SOUL_SHARDS)
	if maxCP == 8 then
		cpBar.combo:SetMinMaxValues(0,5)		
	else
		cpBar.combo:SetMinMaxValues(0,maxCP)
	end
	if maxCP == 6 then
		cpBar.overlay:SetTexCoord(0.015625,0.76,0.109375,0.13671875);
	else
		cpBar.overlay:SetTexCoord(0.015625,0.6328125,0.109375,0.13671875);
	end
end

local dbtypes = { SPELL_AURA_REFRESH = true,
					SPELL_AURA_APPLIED = true,
					SPELL_AURA_REMOVED = true,
					SPELL_AURA_APPLIED_DOSE  = true,
					SPELL_PERIODIC_AURA_REMOVED = true,
					SPELL_PERIODIC_AURA_APPLIED = true,
					SPELL_PERIODIC_AURA_APPLIED_DOSE = true,
					SPELL_PERIODIC_AURA_REFRESH = true,
};
	
local dotEvents = { 
	SPELL_DAMAGE = true,
	SPELL_PERIODIC_DAMAGE = true,
	SPELL_PERIODIC_HEAL = true,
};

local specialEvent = { 
	SPELL_DAMAGE = true,
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_REMOVED = true,
	SPELL_AURA_REFRESH = true,
}; 
local deathEvent = { 
	UNIT_DIED = true,
	UNIT_DESTROYED = true,
	UNIT_DISSIPATES = true,
};

function addon:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, type, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, ...)
	if deathEvent[type] then
		soundBuffer = {};
		return
	end	
	local isOnMe = (destGUID  == UnitGUID("player"))	
	local isMySpell = (sourceGUID == UnitGUID("player"))
	if not isMySpell then 
		return 
	end;


	local saTimerOp = SAMod.ShowTimer.Options
	local select = select
	local SA_Spells = SA_Spells
	local SABars = SA_Data.BARS	
	local isOnTarget = (destGUID == UnitGUID("target"))


	--GCD();
	if dbtypes[type] then
		--Buffs EVENT --
		if SAMod.ShowTimer[spellId] then
			

			local BuffBar = SA_Data.BARS[SA_Spells[spellId].name]
			local spell = SA_Spells[spellId]
			local name, rank, icon, count, debuffType, duration, expirationTime = UnitAura(spell.target, spell.name, nil, Sa_filter[spell.target])
			--fix for absolute corruption
			if spellId == 146739 and duration == 0 then
				expirationTime = SA_Data.tNow + 666.5
				duration = 666.5
				count = 0
			end

			BuffBar["Expires"] = expirationTime or 0;
			BuffBar["tickStart"] = (expirationTime or 0) - SAMod.Sound[spellId].tickStart;
			BuffBar["LastTick"] = BuffBar["tickStart"] - 1.0;
			BuffBar["count"] = count or 0;

			if saTimerOp.Dynamic then addon:UpdateMaxValue(spellId,duration) end;
			if not (name) then
				BuffBar["obj"]:Hide();
			else
				BuffBar["obj"]:Show();
			end
			if SAMod.Sound[spellId].enabled and (type == "SPELL_AURA_REMOVED") and not (name) and (isOnMe or isOnTarget) then
				addon:SA_Sound(LSM:Fetch("sound",SAMod.Sound[spellId].alert),true)
			end			
			addon:SA_ChangeAnchor();
		end
	end
	-- DOT monitors
	if saTimerOp.ShowDoTDmg and dotEvents[type] and (isOnTarget or isOnMe) then
		if SAMod.ShowTimer[spellId]then
			local amount, _, _, _, _, _, critical,_ = select(3, ...)
			local dotText
			if spellId == 218615 then --attribute the "Harverster of Souls" artifact effect to corruption
				dotText = SABars[SA_Spells[146739].name]["obj"].DoTtext
			else
				dotText = SABars[SA_Spells[spellId].name]["obj"].DoTtext
			end

			dotText:SetAlpha(1);
			if (saTimerOp.DoTCrits and critical) then
				dotText:SetFormattedText("*%.0f*", amount);
				UIFrameFadeOut(dotText, 3, 1, 0);
			else
				dotText:SetFormattedText(amount);
				UIFrameFadeOut(dotText, 2, 1, 0);
			end
		end
	end
	if type == "SPELL_AURA_REFRESH" then 
		C_Timer.After(0.2, addon.UpdateTarget) 
	end
	if type == "SPELL_AURA_APPLIED" then 
		addon.UpdateTarget();
	end
end

function addon:UpdateMaxValue(spellId,duration)
	local SpellBar = SA_Data.BARS[SA_Spells[spellId].name]
	local spelld = SA_Spells[spellId].duration

	if not duration then duration = spelld end;
	local dynvalue = duration*0.3

	if duration > spelld then
		dynvalue = spelld*0.3
	end
	SpellBar["obj"]:SetMinMaxValues(0,dynvalue);
	return
end

function addon:UpdateTarget()
	local showT = SAMod.ShowTimer
	local saTimerOp = SAMod.ShowTimer.Options

	for k,v in pairs(showT) do
		local spell = SA_Spells[k]
		if v and spell then
			local spellBar = SA_Data.BARS[spell.name]
			local name, _, _, count, _, duration, expirationTime, _ = UnitAura(spell.target, spell.name, nil, Sa_filter[spell.target]);

			--fix for absolute corruption
			if k == 146739 and duration == 0 then
				expirationTime = SA_Data.tNow + 666.5
				duration = 666.5
				count = 0
			end

			if not (name) then				
				spellBar["tickStart"] = 0;
				spellBar["count"] = 0;
				spellBar["obj"]:Hide();
			else				
				spellBar["Expires"] = expirationTime or 0;
				spellBar["tickStart"] = (expirationTime or 0) - SAMod.Sound[spell.id].tickStart;
				spellBar["LastTick"] = spellBar["tickStart"] - 1.0;
				spellBar["count"] = count or 0;
				if expirationTime > SA_Data.tNow then
					spellBar["obj"]:Show();
				end
				if saTimerOp.Dynamic then 
					addon:UpdateMaxValue(spell.id,duration) 
				end
			end
		end
	end
	addon:SA_ChangeAnchor(); 
end

function addon:BarUpdate(id)
	local spell = SA_Spells[id]
	if SAMod.ShowTimer[id] then
		local spellBar = SA_Data.BARS[spell.name]
		local name, _, _, count, _, duration, expirationTime, _ = UnitAura(spell.target, spell.name, nil, Sa_filter[spell.target]);
		--fix for absolute corruption
		if id == 146739 and duration == 0 then
			expirationTime = SA_Data.tNow + 666.5
			duration = 666.5
			count = 0
		end

		if not (name) then			
			spellBar["tickStart"] = 0;
			spellBar["count"] = 0;
			spellBar["obj"]:Hide();
		else				
			spellBar["Expires"] = expirationTime or 0;
			spellBar["tickStart"] = (expirationTime or 0) - SAMod.Sound[spell.id].tickStart;
			spellBar["LastTick"] = spellBar["tickStart"] - 1.0;
			spellBar["count"] = count or 0;
			if expirationTime > SA_Data.tNow then
				spellBar["obj"]:Show();
			end
			if SAMod.ShowTimer.Options.Dynamic then addon:UpdateMaxValue(spell.id,duration) end
		end
	end
end

function addon:UpdateTormentedSouls()
	_, _, _, count, _, _, _, _, _, _, spellID, _, _, _, _, _, _, _, _ = UnitBuff("player", "Tormented Souls")
	if not count then
		count = 0
	end
	VTimerEnergy:SetMinMaxValues(0, 12);
	VTimerEnergy:SetValue(count)
	SA_Combo:SetFormattedText(count);
end

function addon:UpdateSoulShards()
	local points = UnitPower("player", SPELL_POWER_SOUL_SHARDS); 
	local cpBar = SA_Data.BARS["CP"]["obj"]

	if SAMod.Combo.PointShow then
		cpBar.combo:SetValue(points);	
	end

	return true
end

function addon:CreateComboFrame()
	local f = CreateFrame("Frame", nil, SA);
	local flvl = f:GetFrameLevel()
	local bg = f:CreateTexture(nil, "BACKGROUND");

	local combo = CreateFrame("StatusBar", nil, f);
	local anti = CreateFrame("StatusBar", nil, f);
	local overlay = anti:CreateTexture(nil, "OVERLAY");
	local width = VTimerEnergy:GetWidth();
	local cpC = SAMod.Combo.CPColor
	local cpA = SAMod.Combo.AnColor
	local cpMax = UnitPowerMax("player",SPELL_POWER_SOUL_SHARDS)

	f:ClearAllPoints();
	f:SetSize(width, 10);
	f:SetScale(scaleUI);
	f:SetAllPoints(VTimerEnergy);

	bg:SetTexture(addon:SA_BarTexture("stats"));
	bg:SetAllPoints(f);
	bg:SetVertexColor(0.3, 0.3, 0.3);
	bg:SetAlpha(0.7);

	overlay:SetTexture("Interface\\Archeology\\ArcheologyToast");
	overlay:SetAllPoints(f);
	if cpMax == 6 then
		overlay:SetTexCoord(0.015625,0.76,0.109375,0.13671875);
	else
		overlay:SetTexCoord(0.015625,0.6328125,0.109375,0.13671875);
	end
	combo:SetSize(width, 10);
	combo:SetScale(scaleUI);
	combo:SetFrameLevel(flvl+1)
	combo:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0);
	combo:SetStatusBarTexture(addon:SA_BarTexture("combo"));
	combo:SetStatusBarColor(cpC.r, cpC.g, cpC.b);
	combo:SetMinMaxValues(0, cpMax);
	combo:SetValue(0);
	combo:Show();

	anti:SetSize(width, 5);
	anti:SetScale(scaleUI);
	anti:SetFrameLevel(flvl+2);
	anti:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0);
	anti:SetStatusBarTexture(addon:SA_BarTexture("combo"));
	anti:SetStatusBarColor(cpA.r, cpA.g, cpA.b);
	anti:SetMinMaxValues(0, 3);
	anti:SetValue(0);
	anti:Show()	

	f:SetScript("OnMouseDown", function(self) if (not SAMod.Main.IsLocked) then SA:StartMoving() end end)
	f:SetScript("OnMouseUp", function(self) SA:StopMovingOrSizing(); SAMod.Main.point, _l, _l, SAMod.Main.xOfs, SAMod.Main.yOfs = SA:GetPoint(); end )
	f.bg = bg;
	f.overlay = overlay;
	f.combo = combo;
	f.anti = anti;
	return f;
end

function addon:SA_UpdateCPWidths(width)
	local width = width or VTimerEnergy:GetWidth()

	local f = SA_Data.BARS["CP"]["obj"];
	f:SetWidth(width);
	f.combo:SetWidth(width);
	f.anti:SetWidth(width);
end

function addon:SA_UpdateStatWidths(width)
	local width = width or VTimerEnergy:GetWidth()

	local numStats = SA2.numStats or 3--HP TODO option for this
	local spacing = width/90;
	local cpwidth = ((width-(spacing*3))/(numStats));
	local cur_location = 0; --small initial offset

	local f = SA_Data.BARS["Stat"]["obj"];
	f:SetWidth(width);
	for i = 1, 4 do
		--Create the frame & space it
		local statText = SA_Data.BARS["Stat"]["obj"].stats[i];
		local labelFrame = SA_Data.BARS["Stat"]["obj"].stats[i].lable;
		statText:ClearAllPoints();
		statText:SetPoint("TOPLEFT", f, "TOPLEFT", cur_location, 0)
		statText:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", cur_location + cpwidth, 0)

		labelFrame:ClearAllPoints();
		labelFrame:SetPoint("TOPLEFT", f, "TOPLEFT", cur_location, 0)
		labelFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", cur_location + cpwidth, 0)

		cur_location = cur_location + cpwidth + spacing;
		statText:Show()
		labelFrame:Show()
		if numStats < i then
			statText:Hide()
			labelFrame:Hide()
		end
	end
end

function addon:SA_CreateStatBar()
	local f = CreateFrame("StatusBar", nil, SA);
	local width = widthUI;

	f:ClearAllPoints();
	f:SetSize(width,15);
	f:SetScale(scaleUI);
	f:SetPoint("BOTTOMLEFT", VTimerEnergy, "TOPLEFT", 0, 0) 

	f.bg = f:CreateTexture(nil, "BACKGROUND")
	f.bg:ClearAllPoints() 
	f.bg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 1)
	f.bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -1)
	f.bg:SetTexture(addon:SA_BarTexture("stats"))
	f.bg:SetVertexColor(0.3, 0.3, 0.3)
	f.bg:SetAlpha(0.7)

	f.stats = {true, true, true, true,}

	local numStats = SA2.numStats or 4; --HP TODO option for this
	local spacing = width/60;
	local cpwidth = ((width-(spacing*3))/(numStats));
	local cur_location = 1; --small initial offset

	-- text
	local font = "Fonts\\FRIZQT__.TTF"
	local fontsize = 9
	if (numStats > 3) then
		fontsize = 8;
	end

	local fontstyle = "OUTLINE"
	local lableText = {[1] = "Spell Power",
	[2] = "Mastery",
	[3] = "Haste",
	[4] = "Insight" }
	if SAMod.ShowTimer.Options.BladeFlurry and SA_Data.BFActive then lableText[3] = "Flurry" end
	for i = 1, 4 do
		--Create stat FontString
		local statText = f:CreateFontString("$parentStatText"..i,"ARTWORK","GameFontNormal");
		statText:ClearAllPoints() 
		statText:SetJustifyH("CENTER")
		statText:SetJustifyV("TOP")
		statText:SetFont(font, fontsize, fontstyle);
		statText:SetPoint("TOPLEFT", f, "TOPLEFT", cur_location, 0)
		statText:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", cur_location + cpwidth, 0)

		----Create stat label FontString
		local labelFrame = f:CreateFontString("$parentLableText"..i,"ARTWORK","GameFontNormal");
		labelFrame:SetPoint("TOPLEFT", f, "TOPLEFT", cur_location, 0)
		labelFrame:SetJustifyH("CENTER")
		labelFrame:SetJustifyV("BOTTOM")
		labelFrame:SetFont(font, fontsize/1.6, "");
		labelFrame:SetFormattedText("%s",lableText[i]);

		cur_location = cur_location + cpwidth + spacing;
		f.stats[i] = statText
		f.stats[i].lable = labelFrame

	end
	f:SetScript("OnShow", addon.UpdateStats)	
	f:SetScript("OnMouseDown", function(self) if (not SAMod.Main.IsLocked) then SA:StartMoving() end end)
	f:SetScript("OnMouseUp", function(self) SA:StopMovingOrSizing(); SAMod.Main.point, _l, _l, SAMod.Main.xOfs, SAMod.Main.yOfs = SA:GetPoint(); end )
	return f;
end

function addon:SA_UpdateStats()
	local shadowSP = GetSpellBonusDamage(6);
	local guile = SA_Data.guile;
	local barStats = SA_Data.BARS["Stat"]["obj"].stats
	local mast, mast_coeff = GetMasteryEffect();
	local mastery = mast * mast_coeff;

	barStats[1]:SetFormattedText(shadowSP > 99999 and string.format("%.1fk", shadowSP/1000) or BreakUpLargeNumbers(shadowSP))

	barStats[2]:SetFormattedText("%.1f%%", mast);

	barStats[3]:SetFormattedText("%.1f%%", GetHaste());

	barStats[4]:SetFormattedText(barStats[4] and "%s",SA_Data.guile);	

	if SAMod.Combo.HilightBuffed then
		addon:SA_flashBuffedStats()
	end
end

function addon:SA_flashBuffedStats()
	local baseAP, buffAP, negAP = UnitAttackPower("player");
	local totalAP = baseAP+buffAP+negAP;
	local crit = GetCritChance();
	local mhSpeed, ohSpeed = UnitAttackSpeed("player");	 
	local guile = SA_Data.guile;
	local numStats = SA2.numStats or 3;
	if (not SA_Data.baseAP or SA_Data.baseAP == 0) then --initialize here since all stats = 0 when OnLoad is called.
		addon:SA_ResetBaseStats();
		return
	end

	local statCheck = {true, true, true, true,};
	statCheck[1] = ( (SA_Data.baseAP*2) < (totalAP - buffAP));
	statCheck[2] = (crit > (SA_Data.baseCrit * 1.5)) ;
	statCheck[3] = (mhSpeed < (SA_Data.baseSpeed / 1.5));
	statCheck[4] = (SA_Data.guile == 4 and UnitExists("target"));

	if SA_Data.BFActive then
		statCheck[3] = (tablelength(bfhits) == 0);
	end

	local barStats = SA_Data.BARS["Stat"]["obj"].stats

	for i = 1, numStats do
		local alpha = barStats[i]:GetAlpha();
		if statCheck[i] and SAMod.Combo.HilightBuffed then
			barStats[i]:SetTextColor(140/255, 15/255, 0);
			if (not UIFrameIsFading(barStats[i])) then --flash if not already flashing
				if (alpha > 0.5) then
					UIFrameFadeOut(barStats[i], 1, alpha, 0.1);
				else --UIFrameFlash likes to throw execeptions deep in the bliz ui?
					UIFrameFadeOut(barStats[i], 1, alpha, 1);
				end
			end
		else
			barStats[i]:SetTextColor(1, .82, 0); --default text color
			UIFrameFadeOut(barStats[i], 1, alpha, 1);
		end
	end	
end

function addon:SA_NewFrame()
	local f = CreateFrame("StatusBar", nil, SA);

	f:SetSize(widthUI, 12);
	f:SetScale(scaleUI); 

	f:SetStatusBarTexture(addon:SA_BarTexture());
	f:SetStatusBarColor(0.768627451, 0, 0, 1);
	f:SetMinMaxValues(0, 6.0);
	f:SetValue(0);

	f:Hide();

	f:SetBackdrop({
		bgFile="Interface\\AddOns\\SliceAdmiral\\Images\\winco_stripe_128.tga",
		edgeFile="",
		tile=true, tileSize=1, edgeSize=0,
		insets={left=0, right=0, top=0, bottom=0}
	});
	f:SetBackdropBorderColor(1,1,1,1);
	f:SetBackdropColor(0,0,0,0.5);

	-- text on the right --
	f.text = f:CreateFontString(nil, nil, "GameFontWhite");
	f.text:SetFontObject(SA_Data.BarFont2);
	f.text:SetSize(30,10);
	f.text:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2,0);
	f.text:SetJustifyH("RIGHT");
	f.text:SetFormattedText("");

	-- icon on the left --
	f.icon = f:CreateTexture(nil, "OVERLAY");
	f.icon:SetSize(f:GetHeight(),f:GetHeight());
	f.icon:SetPoint("TOPLEFT", f, "TOPLEFT", -12, 0);
	f.icon:SetBlendMode("DISABLE");

	-- text on the left --
	f.count = f:CreateFontString(nil, nil, "GameFontWhite");
	f.count:SetFontObject(SA_Data.BarFont2);
	f.count:SetSize(80,10);
	f.count:SetPoint("TOPLEFT", f, "TOPLEFT", 2,-1);
	f.count:SetJustifyH("LEFT");
	f.count:SetFormattedText("");

	-- DoT Text --
	f.DoTtext = f:CreateFontString(nil, nil, nil)
	f.DoTtext:SetFontObject(SA_Data.BarFont2);
	f.DoTtext:SetSize(60,10);
	f.DoTtext:SetPoint("CENTER", f, "CENTER", -12 , 0);
	f.DoTtext:SetJustifyH("CENTER");
	f.DoTtext:SetFormattedText("");

	f:SetScript("OnHide", addon.SA_ChangeAnchor);
	f:SetScript("OnShow", addon.SA_ChangeAnchor);	
	f:SetScript("OnMouseDown", function(self) if (not SAMod.Main.IsLocked) then SA:StartMoving() end end)
	f:SetScript("OnMouseUp", function(self) SA:StopMovingOrSizing(); SAMod.Main.point, _l, _l, SAMod.Main.xOfs, SAMod.Main.yOfs = SA:GetPoint(); end )

	return f;
end

function addon:SA_ResetBaseStats()
	local baseAP, buffAP, negAP = UnitAttackPower("player");
	local crit = GetCritChance();
	local mhSpeed, ohSpeed = UnitAttackSpeed("player");

	SA_Data.baseAP = baseAP+buffAP;
	SA_Data.baseCrit = crit;
	SA_Data.baseSpeed = mhSpeed; 
end

function addon:SA_OnLoad()
	addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	addon:RegisterEvent("PLAYER_ENTERING_WORLD")
	addon:RegisterEvent("PLAYER_REGEN_ENABLED")
	addon:RegisterEvent("PLAYER_REGEN_DISABLED")
	addon:RegisterEvent("UNIT_AURA")
	addon:RegisterEvent("PLAYER_TARGET_CHANGED")
	addon:RegisterEvent("PET_BATTLE_CLOSE")
	addon:RegisterEvent("PET_BATTLE_OPENING_START")
	addon:RegisterEvent("UNIT_POWER_FREQUENT");
	addon:RegisterEvent("UNIT_MAXPOWER");
	addon:RegisterEvent("UNIT_ATTACK_POWER")
	addon:RegisterEvent("UNIT_ATTACK_SPEED")
	SA_Data.BarFont = CreateFont("VTimerFont");
	SA_Data.BarFont:SetFont("Fonts\\FRIZQT__.TTF", 12);
	SA_Data.BarFont:SetShadowColor(0,0,0, 0.7);
	SA_Data.BarFont:SetTextColor(1,1,1,0.9);
	SA_Data.BarFont:SetShadowOffset(0.8, -0.8);

	SA_Data.BarFont2 = CreateFont("VTimerFont2");
	SA_Data.BarFont2:SetFont("Fonts\\FRIZQT__.TTF", 8)
	SA_Data.BarFont2:SetShadowColor(0,0,0, 0.7);
	SA_Data.BarFont2:SetTextColor(1,1,1,0.9);
	SA_Data.BarFont2:SetShadowOffset(0.8, -0.8);

	SA_Data.BarFont3 = CreateFont("VTimerFont1O");
	SA_Data.BarFont3:SetFont("Fonts\\FRIZQT__.TTF", 12);
	SA_Data.BarFont3:SetShadowColor(0,0,0, 1);
	SA_Data.BarFont3:SetTextColor(1,1,1,0.8);
	SA_Data.BarFont3:SetShadowOffset(0.8, -0.8);

	SA_Data.BarFont4 = CreateFont("VTimerFont4");
	SA_Data.BarFont4:SetFont("Fonts\\FRIZQT__.TTF", 8)
	SA_Data.BarFont4:SetShadowColor(0,0,0, 0.7); 
	SA_Data.BarFont4:SetShadowOffset(0.8, -0.8);

	local tCo = SAMod.Energy.TextColor
	local Co = SAMod.Energy.ComboTextColor
	VTimerEnergyTxt:SetFontObject(SA_Data.BarFont);
	VTimerEnergyTxt:SetTextColor(tCo.r,tCo.g,tCo.b,tCo.a)
	SA_Combo:SetFontObject(SA_Data.BarFont3);
	SA_Combo:SetTextColor(Co.r,Co.g,Co.b,Co.a)

	VTimerEnergy:SetMinMaxValues(0, 12);
	VTimerEnergy:SetBackdrop({
		bgFile="Interface\\AddOns\\SliceAdmiral\\Images\\winco_stripe_128.tga",
		edgeFile="",
		tile=true, tileSize=1, edgeSize=0,
		insets={left=-1, right=-1, top=-1, bottom=0}
	});

	VTimerEnergy:SetBackdropBorderColor(1,1,1,1);
	VTimerEnergy:SetBackdropColor(0,0,0,0.2);
	VTimerEnergy:SetStatusBarTexture(addon:SA_BarTexture("Energy"));
	VTimerEnergy:SetWidth(200);
	VTimerEnergy:SetScript("OnHide", addon.SA_ChangeAnchor);
	VTimerEnergy:SetScript("OnShow", addon.SA_ChangeAnchor);
	local oEner = SAMod.Energy.Color
	VTimerEnergy:SetStatusBarColor(oEner.r, oEner.g, oEner.b); 
	
	VTimerEnergy:SetScript("OnValueChanged",
		function(self,value) 
			local mi, ma = self:GetMinMaxValues() 
			VTimerEnergyTxt:SetFormattedText(12) 
		end
	) 

	VTimerEnergy:SetValue(UnitPower("player",SPELL_POWER_ENERGY));
	scaleUI = VTimerEnergy:GetScale();
	widthUI = VTimerEnergy:GetWidth();

	S:SmoothBar(VTimerEnergy);

	SA_Data.BARS["CP"]["obj"] = addon:CreateComboFrame();
	SA_Data.BARS["tmp"]["obj"] = addon:SA_NewFrame()
	SA_Data.BARS["Stat"]["obj"] = addon:SA_CreateStatBar();

	SA_Data.BARORDER = {}; -- Initial order puts the longest towards the inside.
	SA_Data.TOPORDER = {};

	for k in pairs(SA_Spells) do
		local color = SAMod.ShowTimer.Colours[k]
		local name = SA_Spells[k].name
		local icont = SA_Spells[k].icon
		local smax = SAMod.ShowTimer.Timers[k]
		local toSort = SA_Spells[k].sort

		if SA_Data.BARS[name] and (SA_Data.BARS[name]["obj"] == 0) then
			SA_Data.BARS[name]["obj"] = addon:SA_NewFrame();
			SA_Data.BARS[name]["obj"]:SetStatusBarColor(color.r, color.g, color.b);
			SA_Data.BARS[name]["obj"].icon:SetTexture(icont);
			SA_Data.BARS[name]["obj"]:SetMinMaxValues(0,smax);
			if toSort then
				SA_Data.BARORDER[#SA_Data.BARORDER+1] = SA_Data.BARS[name];
			else
				SA_Data.TOPORDER[#SA_Data.TOPORDER+1] = SA_Data.BARS[name];
			end
		end
	end

	if SAMod.Combo.ShowStatBar then
		addon:SA_UpdateStats();
	end
	addon.LightTick = false
	if SAMod.Combo.HilightBuffed then
		addon.LightTick = C_Timer.NewTicker(1,addon.SA_flashBuffedStats)
	end
	for k in pairs(SA_Data.BARS) do
		SA_Data.BARS[k]["obj"]:EnableMouse(not SAMod.Main.IsLocked);
	end
	print(string.format(L["SALoaded"], SliceAdmiralVer))
	if (SA) then
		addon:SA_Config_VarsChanged();
		SA:SetAlpha(SAMod.Main.Fade/100);
	end
end

local function SA_UpdateBar(unit, spell, sa_sound)
	local GetTime = GetTime
	local sabars = SA_Data.BARS[spell]
	local sa_time = sabars["Expires"];
	local tickStart = sabars["tickStart"];
	local lastTick = sabars["LastTick"]
	local Showname = SAMod.ShowTimer.Options.ShowNames
	local count = sabars["count"]

	if sa_time > SA_Data.tNow and sabars then
		sabars["obj"]:SetValue(sa_time-SA_Data.tNow);
		sabars["obj"].text:SetFormattedText("%0.1f", sa_time-SA_Data.tNow);
		sabars["obj"].count:SetFormattedText(count > 1 and Showname and string.format("%s (%d)",spell,count) or Showname and spell or count > 1 and count or "");
	else
		sabars["obj"]:Hide();		
		sabars["LastTick"] = 0;
		sabars["count"] = 0;		
		return
	end
	if (sa_time > tickStart) and ((lastTick + 1.0) < GetTime()) then
		addon:SA_Sound(sa_sound,false);
		sabars["LastTick"] = GetTime();
	end
end

local function SA_QuickUpdateBar(unit, spell)
	local sabars = SA_Data.BARS[spell];
	local sa_time = sabars["Expires"];
	local Showname = SAMod.ShowTimer.Options.ShowNames
	local count = sabars["count"]
	local duration = sa_time - SA_Data.tNow



	if sa_time > SA_Data.tNow and sabars then
		if spell == "Corruption" and duration > 600 then
					sabars["obj"]:SetValue(666);
		sabars["obj"].text:SetFormattedText("666");

		else
					sabars["obj"]:SetValue(duration);
		sabars["obj"].text:SetFormattedText("%0.1f", duration);
	end

		sabars["obj"].count:SetFormattedText(count > 1 and Showname and string.format("%s (%d)",spell,count) or Showname and spell or count > 1 and count or "");
	else
		sabars["obj"]:Hide();
	end	 
end

function addon:OnUpdate(elapsed)
	local SATimer = SAMod.ShowTimer
	SA_Data.tNow = GetTime()
	if SAMod.Main.PadLatency then
		local down, up, lag = GetNetStats();
		SA_Data.lag = (lag*2/1000)
	end 

	for k,v in pairs(SATimer) do
		local spell = SA_Spells[k]
		local sound = SAMod.Sound[k]
		if v and spell and sound and sound.enabled then
			SA_UpdateBar(spell.target,spell.name, LSM:Fetch("sound",sound.tick));
		elseif v and spell then
			SA_QuickUpdateBar(spell.target,spell.name);
		end
	end

	-- We need to do this sort here because something could have been
	-- auto refreshed by a proc and we don't get an Update event for that.
	-- But.. only do it once every SA_Data.sortPeriod seconds AND if we have
	-- non-zero timers 

	if SATimer.Options.SortBars then
		if (lastSort > SA_Data.tNow ) then return end
		for i = 1, #SA_Data.BARORDER do
			if (SA_Data.BARORDER[i]["Expires"] > SA_Data.tNow) then
				addon:SA_ChangeAnchor()
				lastSort = SA_Data.tNow + SA_Data.sortPeriod
				return
			end
		end		
	end 

end

function addon:SA_Config_VarsChanged()
	addon:SA_SetScale(SAMod.Main.Scale);
	addon:SA_SetWidth(SAMod.Main.Width);
	local eCo = SAMod.Energy.Color
	local cpC = SAMod.Combo.CPColor
	local cpA = SAMod.Combo.AnColor
	local SACombo = SAMod.Combo

	VTimerEnergy:SetStatusBarColor(eCo.r,eCo.g,eCo.b)
	SA_Data.BARS["CP"]["obj"].combo:SetStatusBarColor(cpC.r,cpC.g,cpC.b); 
	SA_Data.BARS["CP"]["obj"].anti:SetStatusBarColor(cpA.r,cpA.g,cpA.b);

	if SAMod.Energy.ShowEnergy then
		VTimerEnergy:Show();
	else
		VTimerEnergy:Hide();
	end

--	local lManaMax = UnitPowerMax("player",SPELL_POWER_ENERGY);
--	if (lManaMax == 0) then
--		lManaMax = 100
--	end
--	local p1 = SAMod.Energy.Energy1 / lManaMax * SAMod.Main.Width;
--	local p2 = SAMod.Energy.Energy2 / lManaMax * SAMod.Main.Width;
--	SA_Spark1:SetPoint("TOPLEFT", VTimerEnergy, "TOPLEFT", p1, 0);
--	SA_Spark2:SetPoint("TOPLEFT", VTimerEnergy, "TOPLEFT", p2, 0);

	if not SACombo.PointShow and not SACombo.AnticipationShow  then   
		SA_Data.BARS["CP"]["obj"]:Hide();
	else
		SA_Data.BARS["CP"]["obj"]:Show();
	end
	if SAMod.Energy.ShowComboText then
		SA_Combo:Show();			
	else
		SA_Combo:Hide();
	end

	if SACombo.ShowStatBar then
		SA_Data.BARS["Stat"]["obj"]:Show();
	else
		SA_Data.BARS["Stat"]["obj"]:Hide();
	end

	addon:RetextureBars(addon:SA_BarTexture("spells"),"spells");
	addon:RetextureBars(addon:SA_BarTexture("Energy"),"Energy");
	addon:RetextureBars(addon:SA_BarTexture("stats"),"stats");

end

function addon:ResetConfig()
	addon.db:ResetProfile(false,true);
	ReloadUI();
end

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New("SliceAdmiralDB", SADefaults);
	addon.db.profile.playerName = UnitName("player")
	SAGlobal = addon.db.global
	SA2 = addon.db.profile.data
	SAMod = addon.db.profile.Modules
	addon.opt.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db);	
	addon.opt.Main.args = {
		version = {
			name = string.format("%s %s: %s","SliceAdmiral", GAME_VERSION_LABEL, GetAddOnMetadata("SliceAdmiral", "Version")),
			order=90,type = "header"
		},
		lockMovement = {
			name=L["ClickToMove"],
			type="toggle",
			order=1,
			get = function(info) 
				return SAMod.Main.IsLocked; 
			end,
			set = function(info,val) 
				SAMod.Main.IsLocked = val; 
				SA:EnableMouse(not val); 
				VTimerEnergy:EnableMouse(not val);
				for k in pairs(SA_Data.BARS) do 
					SA_Data.BARS[k]["obj"]:EnableMouse(not val); 
				end 
			end
		},
		padLatency = {
			name=L["PadLatency"],
			type="toggle",
			order=3, 
			width="full",
			get = function(info) 
				return SAMod.Main.PadLatency; 
			end,
			set = function(info,val) 
				SAMod.Main.PadLatency = val; 
			end
		},
		resetPost = {
			name=L["ResetPossition"], 
			type = "execute", 
			order=2,
			desc = L["ResetPositionDecs"],
			func = function()
				if (InCombatLockdown()) then 
					addon:Print(ERR_NOT_IN_COMBAT);
				else
					SA:ClearAllPoints();SA:SetPoint("TOPLEFT", 100, -150);
					SAMod.Main.point, _l, _l, SAMod.Main.xOfs, SAMod.Main.yOfs = SA:GetPoint()
				end
			end
		},
		mainInfo = {
			name = L["Main/info"], 
			type = "description", 
			order=4,
			width="full", 
		},
		addonScale = {
			name=L["Main/Scale"],
			type="range",
			width="normal",
			order=11,
			min=50,
			max=200,
			step=1,
			get = function(info) 
				return SAMod.Main.Scale; 
			end,
			set = function(info,val)
				SAMod.Main.Scale = val; 
				addon:SA_SetScale(val); 
			end
		}, 
		barWidth = {
			name=L["Main/Width"],
			type="range",
			width="normal",
			order=12,
			min=25,
			max=300,
			step=5,
			get = function(info) 
				return SAMod.Main.Width; 
			end,
			set = function(info,val) 
				SAMod.Main.Width = val; 
				addon:SA_SetWidth(val); 
			end
		},
		empty = {
			name="",
			type="description",
			order=13,
		},
		fade = {
			name=L["Main/oocFade"],
			type="range",
			width="normal",
			order=14,
			min=0,
			max=100,
			step=1,
			get = function(info) 
				return SAMod.Main.Fade; 
			end,
			set = function(info,val) 
				SAMod.Main.Fade = val; 
				SA:SetAlpha(val/100); 
			end
		},
		barTexture = {
			name=L["Main/Texture"],
			type="select",
			order=15, 
			dialogControl = 'LSM30_Statusbar',
			values = LSM:HashTable("statusbar"),
			get = function(info) 
				return SAMod.Main.BarTexture; 
			end,
			set = function(info,val) 
				SAMod.Main.BarTexture = val; 
				addon:RetextureBars(LSM:Fetch("statusbar",val),"stats"); 
			end
		},
		reset = {
			name = L["ResetDatabase"],
			type = "execute",
			order=100,
			width="full",
			desc = L["ResetDatabaseDesc"],
			func = function()
				if (InCombatLockdown()) then
					addon:Print(ERR_NOT_IN_COMBAT);
				else
					addon.db:ResetDB();
					ReloadUI();
				end
			end
		},
	}

			
	-- Add dual-spec support
	--local LibDualSpec = LibStub('LibDualSpec-1.0')
	--LibDualSpec:EnhanceDatabase(self.db, "SliceAdmiral")
	--LibDualSpec:EnhanceOptions(addon.opt.profile, self.db)
	-- Spec Setup
	addon.db.RegisterCallback(self, "OnNewProfile", "InitializeProfile")
	addon.db.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	addon.db.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	addon.db.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")
end

function addon:InitializeProfile()
	self.db:RegisterDefaults(SADefaults);
end

function addon:UpdateModuleConfigs()
	self.db:RegisterDefaults(SADefaults);
end

function addon:AddOption(name, Table, displayName)
	AceConfig:RegisterOptionsTable("SliceAdmiral"..name, Table);
	AceConfigDialog:AddToBlizOptions("SliceAdmiral"..name, displayName, "SliceAdmiral");
end

function addon:SlashCommand(Arg)	
	SAMod.Main.IsLocked = not SAMod.Main.IsLocked;
	SA:EnableMouse(not SAMod.Main.IsLocked); 
	VTimerEnergy:EnableMouse(not SAMod.Main.IsLocked);
	for k in pairs(SA_Data.BARS) do
		SA_Data.BARS[k]["obj"]:EnableMouse(not SAMod.Main.IsLocked); 
	end
end

function addon:OnEnable()
	AceConfig:RegisterOptionsTable("SliceAdmiral", addon.opt.Main);
	self.optionsFrame = AceConfigDialog:AddToBlizOptions("SliceAdmiral");
	if addon:GetModule("ShowTimer", true) then addon:AddOption("ShowTimer Bars", addon.opt.ShowTimer, L["TimerBars"]); end;
	if addon:GetModule("Combo", true) then addon:AddOption("Combo Points", addon.opt.Combo, L["Combo"]) end
	if addon:GetModule("Energy", true) then addon:AddOption("Energy Bar", addon.opt.Energy, L["EnergyBar"]) end
	--addon:AddOption("Profiles", addon.opt.profile, "Profiles"); --Localization Needed
	local localizedClass, englishClass = UnitClass("player");
	local point, xOfs, yOfs = SAMod.Main.point, SAMod.Main.xOfs, SAMod.Main.yOfs
	print("Honk: 2");
	print(englishClass);
	if (englishClass == "WARLOCK") then
		for k in pairs(SA_Spells) do
			SA_Data.BARS[SA_Spells[k].name] = {	
				["obj"] = 0,
				["Expires"] = 0,		-- expire time until GetTime()
				["LastTick"] = 0,
				["tickStart"] = 0,
				["count"] = 0,
				["id"]=SA_Spells[k].id or 0,
			}
		end
		addon:SA_OnLoad()
		SA:ClearAllPoints(); SA:SetPoint(point, xOfs, yOfs);
		addon.UpdateTicker = C_Timer.NewTicker(SA2.UpdateInterval, addon.OnUpdate);
		SA:SetScript("OnMouseDown", function(self) if (not SAMod.Main.IsLocked) then self:StartMoving() end end);
		SA:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing(); SAMod.Main.point, _l, _l, SAMod.Main.xOfs, SAMod.Main.yOfs = SA:GetPoint(); end );
		SA:EnableMouse(not SAMod.Main.IsLocked);
		VTimerEnergy:SetScript("OnMouseDown", function(self) if (not SAMod.Main.IsLocked) then SA:StartMoving() end end);
		VTimerEnergy:SetScript("OnMouseUp", function(self) SA:StopMovingOrSizing(); SAMod.Main.point, _l, _l, SAMod.Main.xOfs, SAMod.Main.yOfs = SA:GetPoint(); end );
		VTimerEnergy:EnableMouse(not SAMod.Main.IsLocked);
		addon:SA_SetScale(SAMod.Main.Scale);
		addon:SA_SetWidth(SAMod.Main.Width);
		SlashCmdList["SliceAdmiral_Command"] = addon.SlashCommand;
		SLASH_SliceAdmiral_Command1 = "/SliceAdmiral";
	else
		addon:UnregisterAllEvents();
		SA:Hide();
		DisableAddOn("SliceAdmiral");
	end
end
