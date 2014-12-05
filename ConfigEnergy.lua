local sliceadmiral = LibStub("AceAddon-3.0"):GetAddon("SliceAdmiral");
local L = LibStub("AceLocale-3.0"):GetLocale("SliceAdmiral", true);
local addon = sliceadmiral:NewModule("Energy");
local lUnitManaMax = UnitManaMax("player")

function addon:OnInitialize()
	local energy = lUnitManaMax
	local Co = SAMod.Energy.Color;
	if (energy < 50) then
		energy = 100
	end
	sliceadmiral.opt.Energy.args = { 
			enable = {name=L["energy/Show"],type="toggle",order=1,	
				get = function(info) return SAMod.Energy.ShowEnergy; end,
				set = function(info,val) SAMod.Energy.ShowEnergy = val;
							if val then 
								VTimerEnergy:Show();
							else 
								VTimerEnergy:Hide();
							end
						end,
			},
			showcp = {name=L["energy/ShowCombo"],type="toggle",order=2,width="full",
					get = function(info) return SAMod.Energy.ShowComboText; end, 
					set = function(info,val) SAMod.Energy.ShowComboText=val;
						if not (SAMod.Energy.ShowComboText) and not (SAMod.Energy.AnticpationText) then
							SA_Combo:Hide();							
						else
							SA_Combo:Show();							
						end
					end,
				},
			showanti = {name=L["energy/ShowAnti"],type="toggle",order=3,width="full",
					get = function(info) return SAMod.Energy.AnticpationText; end, 
					set = function(info,val) SAMod.Energy.AnticpationText=val;
						if not (SAMod.Energy.ShowComboText) and not (SAMod.Energy.AnticpationText) then
							SA_Combo:Hide();							
						else
							SA_Combo:Show();							
						end
					end,
				},
			marker1 = {name=L["energy/mark1"],type="range",order=4,
				min=1,max=energy,step=1,
				get = function(info) return SAMod.Energy.Energy1; end,
				set = function(info,val) SAMod.Energy.Energy1 = val; 
						local p1 = val / energy * SAMod.Main.Width;
						SA_Spark1:SetPoint("TOPLEFT", VTimerEnergy, "TOPLEFT", p1, 0);
					end,
			},
			marker2 = {name=L["energy/mark2"],type="range",order=5,
				min=1,max=energy,step=1,
				get = function(info) return SAMod.Energy.Energy2; end,
				set = function(info,val) SAMod.Energy.Energy2 = val; 
						local p2 = val / energy * SAMod.Main.Width;
						SA_Spark2:SetPoint("TOPLEFT", VTimerEnergy, "TOPLEFT", p2, 0);
					end,
			},
			empty1 = {name="",type="description",order=6,},
			ealert1 = {name=L["AlertSound"],type="select",order=13,disabled=true,
				values = SA_ASounds,
				get = function(info) return SAMod.Energy.EnergySound1; end,
				set = function(info,val) SAMod.Energy.EnergySound1 = val;			
				end
			},
			ealert2 = {name=L["AlertSound"],type="select",order=14,disabled=true,
				values = SA_ASounds,
				get = function(info) return SAMod.Energy.EnergySound2; end,
				set = function(info,val) SAMod.Energy.EnergySound2 = val;			
				end
			},
			empty = {name="", type="description", order=15, },
			trancp = { name=L["energy/transp"],type="range",order=16,
				min=1,max=100,step=1,
				get =function(info) return SAMod.Energy.EnergyTrans; end,
				set = function(info,val) SAMod.Energy.EnergyTrans = val; end,
			},
			texture = {name=L["Main/Texture"],type="select",order=17, dialogControl = 'LSM30_Statusbar',
				values = SA_BarTextures,				
				get = function(info) return SA_Text[SAMod.Energy.BarTexture]; end,				
				set = function(info,val) SAMod.Energy.BarTexture = SA_BarTextures[val]; sliceadmiral:RetextureBars(SA_BarTextures[val],"Energy") end,
			},
			texColor = { name=L["energy/Color"], type="color", order=2,width="double",
				get = function(info) return Co.r, Co.g,Co.b,Co.a; end,
				set = function(info, r,g,b,a) VTimerEnergy:SetStatusBarColor(r,g,b); Co.r = r; Co.g = g; Co.b = b; end,
			},			
		};
end