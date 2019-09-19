local LibRPMedia = LibStub:GetLibrary("LibRPMedia-1.0");
local iconList = {};

for _, name in LibRPMedia:FindIcons(filter or "", { method = "substring" }) do
	iconList[#iconList + 1] = name;
end

select(2, ...).ICON_LIST = iconList;