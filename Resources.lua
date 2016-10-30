-- Author      : Administrator
-- Create Date : 9/13/2008 10:16:36 AM
--0 Shared 1 Assassination, 2 Combat, 3 Subtlety 4 Talents
SA_Spells = { 
	[980] = { target = "target", sort = true,duration=18, pandemic=true, spec=0,},  --Agony Rank 2 (Rank 1 id: 980)
	[63106] = { target = "target", sort = true,duration=15, pandemic=true, spec=0,},  --Siphon Life
	[146739] = { target = "target", sort = true,duration=14, pandemic=true, spec=0,},  --Corruption
	[205179] = { target = "target", sort = true,duration=14, pandemic=false, spec=0,},  --Phantom Singulatiry
	[216708] = { target = "player", sort = true,duration=60, pandemic=false,spec=0,}, --Deadwind Harverster
	[233490] = { target = "target", sort = true,duration=7, pandemic=false, spec=0,},  --Unstable Affliction
	-- [199740] = {target="pet",sort=true,duration=300, pandemic=false, spec=2,}, --Bribe
};

for k in pairs(SA_Spells) do
	local name, rank, icon, _ = GetSpellInfo(k)
	if not name then print(k) end
	SA_Spells[k].name = name or "none"..k
	SA_Spells[k].icon = icon or "blank"
	SA_Spells[k].id = k
end

local LSM = LibStub("LibSharedMedia-3.0")
local SA_BarTextures = {
	["Aluminium"] = "Interface\\AddOns\\SliceAdmiral\\Images\\Aluminium.tga",
	["BantoBar"] = "Interface\\AddOns\\SliceAdmiral\\Images\\BantoBar.tga",
	["Gloss"] = "Interface\\AddOns\\SliceAdmiral\\Images\\Gloss.tga",
	["Healbot"] = "Interface\\AddOns\\SliceAdmiral\\Images\\HealBot.tga",
	["LiteStep"] = "Interface\\AddOns\\SliceAdmiral\\Images\\LiteStep.tga",
	["Runes"] = "Interface\\AddOns\\SliceAdmiral\\Images\\Runes.tga",
	["Smooth"] = "Interface\\AddOns\\SliceAdmiral\\Images\\Smooth.tga",
};
for k,v in pairs(SA_BarTextures) do 
	LSM:Register("STATUSBAR", k, v)	
end

local SA_Sounds = {
	["Price is WRONG"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\PriceIsWrong.ogg",
	["Waaaah"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\Old Trumpet A 01.ogg",
	["BassDrum"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\6OP00084.ogg",
	["Tambourine"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\tambourine.ogg",
	["Cowbell"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\cowtown.ogg",
	["SliceClick"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\FXHit15.ogg",
	["BoomBoomClap"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\HoleA.ogg",
	["Marching Band"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\OldDrums2.ogg",
	["High Hat 4"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\perc09_HH.ogg",
	["BoomBoomThak"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\RawB.ogg",
	["Arpeggiator C2"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\Arp31-C2.ogg",
	["Arpeggiator C3"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\Arp31-C3.ogg",
	["Arpeggiator C4"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\Arp31-C4.ogg",
	["ScratchShot"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\ScratchShot.ogg",
	["StunningHit"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\StunningHit.ogg",
	["DNBLoop4"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\DNBLoop4.ogg",
	["DNBLoop2"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\DNBLoop2.ogg",
	["Scratch4"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\Scratch4.ogg",
	["You Spin Me"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\youspin.ogg",
	["What's the Deal?"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\whats-the-deal.ogg",
	["ClubBeatJ"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\ClubBeatJ.ogg",
	["Growl"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\growl.ogg",
	["OH YEAH"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\OH-YEAH.ogg",
	["Shaker"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\shaker.ogg",
	["Pop"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\pop.ogg",
	["Drum Rattle"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\drumrattle.ogg",
	["Ping"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\pingit.ogg",
	["Switch On/Off"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\switch-on-off.ogg",
	["Eth Perc Short"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\perc-short.ogg",
	["Eth Perc Long"] = "Interface\\AddOns\\SliceAdmiral\\Audio\\perc-long.ogg",
	["None"] = "Interface\Quiet.ogg",
};

for k,v in pairs(SA_Sounds) do
	LSM:Register("SOUND", k,v)	
end
