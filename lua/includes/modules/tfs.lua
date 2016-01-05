local error = error
local type = type
local pairs = pairs
local ipairs = ipairs
local loadstring = loadstring
local load = load
local CompileString = CompileString
local gmod = gmod and true
local unpack = table.unpack or unpack
local setmetatable = setmetatable
local getmetatable = (debug and debug.getmetatable) or getmetatable

TFS = {}

TFS.BaseFS = {}
do
	local FS = TFS.BaseFS

	FS.meta = {}

	FS.meta.name = "Base Filesystem"

	FS.reservedNames = {
		[".."] = true,
		["."] = true,
		["__ident"] = true
	}

	FS.data = {
		__ident = "/"
	}
	FS.data[".."] = FS.data
	FS.currentDir = FS.data
	FS.path = "/"

	function FS:CreateDir(name)
		if name:sub(-1,-1) ~= "/" then name = name.."/" end
		local name,path,dir = self:ChangeDir(name,false,true)
		if self.reservedNames[name] then error("Reserved name") end
		dir[name] = {
			[".."] = dir,
			__ident = path..name.."/"
		}
	end

	function FS:Exists(name)
		local name,path,dir = self:ChangeDir(name,true)
		if self.reservedNames[name] then error("Reserved name") end
		return (type(dir[name]) ~= "nil"),(type(dir[name]) == "table")
	end

	function FS:Delete(name)
		local name,path,dir = self:ChangeDir(name,true)
		if self.reservedNames[name] then error("Reserved name") end
		self.currentDir[name] = nil
	end

	function FS:Write(name,data)
		local name,path,dir = self:ChangeDir(name,true)
		if self.reservedNames[name] then error("Reserved name") end
		if(type(dir[name]) == "table") then
			error("Attempt to write to a folder")
		else
			dir[name] = data or ""
		end
	end

	function FS:Read(name)
		local name,path,dir = self:ChangeDir(name,true)
		if self.reservedNames[name] then error("Reserved name") end
		if(type(dir[name]) == "table") then
			error("Attempt to read a folder")
		else
			return dir[name]
		end
	end

	function FS:Append(name,data)
		local name,path,dir = self:ChangeDir(name,true)
		if self.reservedNames[name] then error("Reserved name") end
		if(type(dir[name]) == "table") then
			error("Attempt to write to a folder")
		else
			dir[name] = (dir[name] or "")..(data or "")
		end
	end

	function FS:Folders()
		local folders = {}
		for entry,data in pairs(self.currentDir) do
			if (type(data) == "table") and not self.reservedNames[entry] then
				folders[#folders+1] = entry
			end
		end
		return folders
	end

	function FS:Files()
		local files = {}
		for entry,data in pairs(self.currentDir) do
			if (type(data) ~= "table") and not self.reservedNames[entry] then
				files[#files+1] = entry
			end
		end
		return files
	end

	function FS:ChangeDir(path,doFileName,ignoreLastDir)
		path = path:gsub("\\","/")

		if ((doFileName==nil) and (ignoreLastDir==nil)) then path = path.."/" end

		local cDir,cPath
		if(path:sub(1,1) == "/") then
			cDir = self.data
			cPath = "/"
		else
			cDir = self.currentDir
			cPath = self.path
		end

		do
			local path = path
			local traverse = true
			if ignoreLastDir then
				if path:match("(.+/).-/") then
					path = path:match("(.+/).-/")
				else
					traverse = false
				end
			end

			if traverse then
				for dir in path:gmatch("([^/]+)/") do
					if(type(cDir[dir]) == "table") then
						cDir = cDir[dir]
						cPath = cDir.__ident
					else
						error(cPath..dir.." is not a folder!")
					end
				end
			end
		end

		if doFileName then
			local fileName,_ = path:match("[^/]+$")

			if not fileName or fileName == "" then
				error("Expected a filename in the filepath string!")
			else
				return fileName,cPath,cDir
			end
		elseif(doFileName == false) then
			local folderName,_ = path:match("([^/]+)/$")

			if not folderName or folderName == "" then
				error("Expected a folder name in the filepath string!")
			else
				return folderName,cPath,cDir
			end
		else
			self.currentDir = cDir
			self.path = cPath
		end
	end

	function FS:Dir()
		return self.path
	end

	function FS:SearchFile(name,recurse,stringPatterns,matches)
		local matches = matches or {}

		for _,fileName in ipairs(self:Files()) do
			if fileName:find(name,1,not stringPatterns) then
				matches[#matches+1] = self:Dir()..fileName
			end
		end

		if recurse then
			for _,folderName in ipairs(self:Folders()) do
				self:ChangeDir(folderName)
				self:SearchFile(name,recurse,stringPatterns,matches)
				self:ChangeDir("..")
			end
		end

		return matches
	end

	function FS:SearchFolder(name,recurse,stringPatterns,matches)
		local matches = matches or {}

		for _,folderName in ipairs(self:Folders()) do
			if folderName:find(name,1,not stringPatterns) then
				matches[#matches+1] = self:Dir()..folderName
			end

			if recurse then
				self:ChangeDir(folderName)
				self:SearchFolder(name,recurse,stringPatterns,matches)
				self:ChangeDir("..")
			end
		end

		return matches
	end

	function FS:RunLua(name,...)
		local name,path,dir = self:ChangeDir(name,true)
		if gmod then
			local func = CompileString(self:Read(path..name),path..name)

			if type(func) == "function" then
				return func(...)
			else
				error(func)
			end
		else
			local runFunc = loadstring or load

			local func,err = runFunc(self:Read(path..name))

			if func then
				return func(...)
			else
				error(err)
			end
		end
	end

	function FS:ToData()
		return {
			data = self.data,
			meta = self.meta
		}
	end

	setmetatable(FS,{
		__tostring = function(self)
			return "Filesystem ["..self.meta.name.."]"
		end
	})
end

TFS.lib = {}

function TFS.lib.deepCopy(tbl,new,lookup)
	new = new or {}
	lookup = lookup or {[tbl]=new}

	local meta = getmetatable(tbl)
	if meta then setmetatable(new,TFS.lib.deepCopy(meta),{},lookup) end

	for k,v in pairs(tbl) do
		if(type(k) == "table") then
			if(lookup[k]) then
				k = lookup[k]
			else
				lookup[k] = {}
				k = TFS.lib.deepCopy(k,lookup[k],lookup)
			end
		end

		if(type(v) == "table") then
			if(lookup[v]) then
				new[k] = lookup[v]
			else
				lookup[v] = {}
				new[k] = TFS.lib.deepCopy(v,lookup[v],lookup)
			end
		else
			new[k] = v
		end
	end

	return new
end

function TFS.New(name)
	local FS = TFS.lib.deepCopy(TFS.BaseFS)
	FS.meta.name = name
	return FS
end

function TFS.FromData(data)
	local FS = TFS.lib.deepCopy(TFS.BaseFS)
	FS.meta = data.meta
	FS.data = data.data
	FS.currentDir = data.data
	return FS
end

return TFS
