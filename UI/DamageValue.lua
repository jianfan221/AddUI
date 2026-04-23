-- --by:简繁,伤害统计始终简化数值
local NumberData = {
	config = CreateAbbreviateConfig({
		{
			breakpoint = 1e10,--123亿
			abbreviation = "亿",
			significandDivisor = 1e8,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e9,--12.3亿
			abbreviation = "亿",
			significandDivisor = 1e7,
			fractionDivisor = 10,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e8,--1.23亿
			abbreviation = "亿",
			significandDivisor = 1e6,
			fractionDivisor = 100,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e6,--123万
			abbreviation = "万",
			significandDivisor = 1e4,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1e4,--1.2万
			abbreviation = "万",
			significandDivisor = 1e3,
			fractionDivisor = 10,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1,
			abbreviation = "",
			significandDivisor = 1,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
	}),
}
local function GetMainValue(entry)
	if entry.valuePerSecond ~= nil and entry:ShowsValuePerSecondAsPrimary() then
		return entry.valuePerSecond;
	end

	if entry.value ~= nil then
		return entry.value;
	end

	return 0;
end
local function GetParentheticalValue(entry)
	if entry.value ~= nil and entry:ShowsValuePerSecondAsPrimary() then
		return entry.value;
	end

	if entry.valuePerSecond ~= nil then
		return entry.valuePerSecond;
	end

	return 0;
end

local function GetEntryValueText(value, parentheticalValue)
	if parentheticalValue ~= nil then
		return DAMAGE_METER_ENTRY_FORMAT_COMPACT:format(AbbreviateNumbers(value,NumberData), AbbreviateNumbers(parentheticalValue,NumberData));
	else
		return DAMAGE_METER_ENTRY_FORMAT_MINIMAL:format(AbbreviateNumbers(value,NumberData));
	end
end
local numberDisplayTypeFormatters =
{
	[Enum.DamageMeterNumbers.Minimal] = function(entry) return GetEntryValueText(GetMainValue(entry)); end,
	[Enum.DamageMeterNumbers.Compact] = function(entry) return GetEntryValueText(GetMainValue(entry), GetParentheticalValue(entry)); end,
}
local function GetValueText(self)
	return numberDisplayTypeFormatters[self:GetNumberDisplayType()](self);
end
hooksecurefunc(DamageMeterEntryMixin, "Init", function(self)
	if not AddUIDB.valueda then return end
	if self.MYHOOK then return end
	self.MYHOOK = true
	hooksecurefunc(self, "UpdateValue", function(bar)
		if bar:GetNumberDisplayType() == Enum.DamageMeterNumbers.Complete then
			return
		end
		local success, text = pcall(GetValueText, bar)
		if success and text then
			bar:GetValue():SetText(text);
		end
	end)
end)
