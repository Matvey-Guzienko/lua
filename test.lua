script_name("Auto-Nak.release-1.0.0")
script_version("28.09.2023")
local enable_autoupdate = true -- false to disable auto-update + disable sending initial telemetry (server, moonloader version, script version, samp nickname, virtual volume serial number)
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'���������� ����������. ������� ���������� c '..thisScript().version..' �� '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('��������� %d �� %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('�������� ���������� ���������.')sampAddChatMessage(b..'���������� ���������!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'���������� ������ ��������. �������� ���������� ������..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': ���������� �� ���������.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': �� ���� ��������� ����������. ��������� ��� ��������� �������������� �� '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, ������� �� �������� �������� ����������. ��������� ��� ��������� �������������� �� '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "http://144.126.154.29:25637/api/script/checkupdate"
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/qrlk/moonloader-script-updater/"
        end
    end
end
local sampev = require("samp.events")
local copas = require('copas')
local http = require('copas.http')
local lthreads = require("lthreads")
local vkeys = require('vkeys')
local socket = require("socket")
local inicfg = require('inicfg')
local wm = require('lib.windows.message')

local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local settings = inicfg.load({main = {time_wait_form = 15, key_accept_form = vkeys.VK_F4}}, 'autonak.ini')
inicfg.save(settings, 'autonak.ini')

local forma, nickform, timeform, status_formi = "", "", 0, false
local togglecheck = true
local tagchat = '{c92800}Auto-Nak{ffffff}: '
local debugmode = true
local statusnotf = false
local chatglobal = {"VIP ADV", "PREMIUM", "VIP", "FOREVER", "����� ����������� �������","��������","�������","������������","�������","����������","��������","�������� ���������","��������� �����������","�������� ��������","��������� ���������", "�������", "�������� �������", "�������� �������������", "������� ������", "������������ ���������", "������������ ������", "��������� �����", "�������� ��������", "���������"}

function onWindowMessage(msg, wparam, lparam)
	if msg == wm.WM_KILLFOCUS then
		togglecheck = false
	end
	if msg == wm.WM_SETFOCUS then
		togglecheck = true
	end
end

function httpRequest(request, body, handler)
    if not copas.running then
        copas.running = true
        lthreads.func(function(wait)
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end

function url_encode(text)
	local text = string.gsub(text, "([^%w-_ %.~=])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)
	local text = string.gsub(text, " ", "+")
	return text
end

function main()
    while not isSampAvailable() do wait(0) end
    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end
    sampAddChatMessage(tagchat .. 'Started!', -1)
	local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	clientName = sampGetPlayerNickname(id)
    httpRequest('http://144.126.154.29:25637/api/loginingame?nick=' .. clientName, nil, function (e,r)
        if r == 200 then
            if debugmode then
                sampAddChatMessage(tagchat .. 'Debug request: ' .. u8:decode(e), -1)
            end
            local response = decodeJson(u8:decode(e))
            if response['login'] then
                sampAddChatMessage(tagchat .. response['message'], -1)
            else
                sampAddChatMessage(tagchat .. "� ��� ����������� ������ � ����.", -1)
                thisScript():unload()
            end
        else
            print('Request error, status code: ' .. r)
        end
    end)
    lthreads.func(function(wait)
        while true do
            httpRequest("http://144.126.154.29:25637/api/active?nick=" .. clientName, nil, function (e, r)
                if r == 200 then
                    if debugmode then
                        sampAddChatMessage(tagchat .. 'Debug request: ' .. u8:decode(e), -1)
                    end
                    local response = decodeJson(u8:decode(e))
                    if not response['message'] then
                        sampAddChatMessage(tagchat .. "� ��� ����������� ������ � ����.", -1)
                        thisScript():unload()
                    end
                else
                    print('Request error, status code: ' .. r)
                end
            end)
            wait(10000)
        end
    end)
    sampRegisterChatCommand('archbot_debug', function ()
		debugmode = not debugmode
		sampAddChatMessage(tagchat .. 'Debug mode: ' .. tostring(debugmode), -1)
	end)

    while true do
        wait(0)
        lthreads.checkThreads()
        if isKeyJustPressed(settings.main.key_accept_form) then
			local checktime = os.time() - timeform
			if checktime <= settings.main.time_wait_form and status_formi then
				status_formi = false
				statusnotf = false
				sampProcessChatInput(forma)
				sampAddChatMessage(tagchat .. '�� ������� {1aff00}�������{ffffff} ����� �� ������!', -1)
				printStyledString("~g~~h~Form accepted", 3000, 5)
			else
				status_formi = false
				statusnotf = false
				sampAddChatMessage(tagchat .. '�� ������ ������ ��� ���������� ���� ��� ������ ���������!', -1)
			end
		end
    end
end

function createNotf()
    if not statusnotf then statusnotf = false end
    while true do
        if statusnotf then
            local currentTime = os.time()
            local remainingTime = currentTime - timeform
            if remainingTime <= settings.main.time_wait_form then
                printStyledString("~y~~h~Press " .. vkeys.id_to_name(settings.main.key_accept_form) .."!", 2000, 5)
            else
                statusnotf = false
                printStyledString("~y~~h~You missed the form", 5000, 5)
            end
        end
        wait(1000)
    end
end

function addform(ggggg, formai, nicki, idi, textio)
    forma, nickform, timeform, status_formi = formai, nicki, os.time(), true
    sampAddChatMessage(tagchat .. '����� {0080ff}' .. tostring(nicki) .. '[' .. tostring(idi) ..']{ffffff} ������� ������� �������!', -1)
    sampAddChatMessage(tagchat .. '������� {c92800}' .. vkeys.id_to_name(settings.main.key_accept_form) .. '{ffffff} ��� ������� ������ �����: {9f63ff}' .. forma, -1)
	sampAddChatMessage(tagchat .. textio, -1)
    createNotf()
end

function sampev.onServerMessage(color, text)
    if togglecheck then
        local tag = string.match(text, '%[(.*)%]%s.*%[%d+%]:%s.*')
		for _, word in ipairs(chatglobal) do
			if tag == word then
                httpRequest('http://144.126.154.29:25637/api/checkchat?nick=' .. clientName .. '&text=' .. url_encode(u8(text):gsub('{......}', '')), nil, function (e, r)
                    if r == 200 then
                        if debugmode then
                            sampAddChatMessage(tagchat .. 'Debug request: ' .. u8:decode(e), -1)
                        end
                        local response = decodeJson(u8:decode(e))
                        if response['check'] == "success" then
                            lthreads.func(addform, response['forma'], response['nick'], response['id'], text)
                        end
                    else
                        print('Request error, status code: ' .. r)
                    end
                end)
            end
        end
    end
end