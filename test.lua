script_name("Auto-Nak.release-1.0.0")
script_version("28.09.2023")
local sampev = require("samp.events")
local copas = require('copas')
local http = require('copas.http')
local lthreads = require("lthreads")
local vkeys = require('vkeys')
local socket = require("socket")
local inicfg = require('inicfg')
local wm = require('lib.windows.message')
local dlstatus = require('moonloader').download_status

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
local chatglobal = {"VIP ADV", "PREMIUM", "VIP", "FOREVER", "Пилот гражданской авиации","Пожарный","Механик","Дальнобойщик","Таксист","Инкассатор","Мусорщик","Работник налоговой","Развозчик металлолома","Водитель автобуса","Развозчик продуктов", "Адвокат", "Водитель трамвая", "Машинист электропоезда", "Главный фермер", "Руководитель грузчиков", "Руководитель завода", "Ремонтник дорог", "Продавец хотдогов", "Парковщик"}

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

function autoupdate(json_url, prefix, url)
    local dlstatus = require('moonloader').download_status
    local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
    if doesFileExist(json) then os.remove(json) end
    downloadUrlToFile(json_url, json, function(id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            if doesFileExist(json) then
                local f = io.open(json, 'r')
                if f then
                    local info = decodeJson(f:read('*a'))
                    updatelink = info.updateurl
                    updateversion = info.latest
                    f:close()
                    os.remove(json)
                    if updateversion ~= thisScript().version then
                        lua_thread.create(function(prefix)
                        local dlstatus = require('moonloader').download_status
                        local color = -1
                        sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                        wait(250)
                        downloadUrlToFile(updatelink, thisScript().path,
                            function(id3, status1, p13, p23)
                                if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                                    print(string.format('Загружено %d из %d.', p13, p23))
                                elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                                    print('Загрузка обновления завершена.')
                                    sampAddChatMessage((prefix..'Обновление завершено!'), color)
                                    goupdatestatus = true
                                    lua_thread.create(function() wait(500) thisScript():reload() end)
                                end
                                if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                                    if goupdatestatus == nil then
                                        sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                                        update = false
                                    end
                                end
                            end)
                        end, prefix)
                    else
                        update = false
                        print('v'..thisScript().version..': Обновление не требуется.')
                    end
                end
            else
                print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
                update = false
            end
        end
    end)
    while update ~= false do wait(100) end
end

function main()
    while not isSampAvailable() do wait(0) end
    autoupdate("http://144.126.154.29:25637/api/script/checkupdate", '['..string.upper(thisScript().name)..']: ', "https://vk.com/archgilbert")
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
                sampAddChatMessage(tagchat .. "У вас отсутствует доступ в боте.", -1)
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
                        sampAddChatMessage(tagchat .. "У вас отсутствует доступ в боте.", -1)
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
				sampAddChatMessage(tagchat .. 'Вы успешно {1aff00}приняли{ffffff} форму на игрока!', -1)
				printStyledString("~g~~h~Form accepted", 3000, 5)
			else
				status_formi = false
				statusnotf = false
				sampAddChatMessage(tagchat .. 'На данный момент нет актуальных форм для выдачи наказания!', -1)
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
    sampAddChatMessage(tagchat .. 'Игрок {0080ff}' .. tostring(nicki) .. '[' .. tostring(idi) ..']{ffffff} нарушил правила сервера!', -1)
    sampAddChatMessage(tagchat .. 'Нажмите {c92800}' .. vkeys.id_to_name(settings.main.key_accept_form) .. '{ffffff} для быстрой выдачи формы: {9f63ff}' .. forma, -1)
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

-- ver2