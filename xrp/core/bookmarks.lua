--[[
	(C) 2014 Justin Snelgrove <jj@stormlord.ca>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

xrp.bookmarks = setmetatable({}, {
	__index = function (self, character)
		character = xrp:NameWithRealm(character)
		if not character or not xrp_cache[character] then
			return nil
		end
		return xrp_cache[character].own and 0 or xrp_cache[character].bookmark
	end,
	__newindex = function(self, character, bookmark)
		character = xrp:NameWithRealm(character)
		if not character or not xrp_cache[character] then
			return nil
		end
		if bookmark and not xrp_cache[character].bookmark then
			xrp_cache[character].bookmark = time()
		elseif not bookmark and xrp_cache[character].bookmark then
			xrp_cache[character].bookmark = nil
		end
	end,
	__metatable = false,
})
