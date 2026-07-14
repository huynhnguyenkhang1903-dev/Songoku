-- Đường dẫn đến 3 thư mục chứa xe của bạn (tự động nhận diện đường dẫn thực tế của server)
local pathNoShop = GetResourcePath("rpv_car_not_inshop")
if pathNoShop then pathNoShop = (pathNoShop .. "/data"):gsub("/", "\\") end

local pathShop = GetResourcePath("rpv_car_inshop")
if pathShop then pathShop = (pathShop .. "/data"):gsub("/", "\\") end

local pathNganh = GetResourcePath("rpv_lawandservice_pack")
if pathNganh then pathNganh = (pathNganh .. "/data"):gsub("/", "\\") end

local function _trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function _uniqueInsert(t, v)
    for _, existing in ipairs(t) do
        if existing == v then return end
    end
    table.insert(t, v)
end

-- Hàm quét danh sách hệ thống Windows
-- - Shop / NoShop: chỉ lấy TÊN THƯ MỤC con trong stream (mã xe)
-- - Xe ngành: giữ nguyên cơ chế quét file trong data
local function _normalizeModelName(fileName)
    local model = tostring(fileName or ""):gsub("%.[^%.]+$", "")
    model = _trim(model)
    model = model:gsub("_hi$", "")
    return model
end

local function GetVehicleModels(dirPath)
    if not dirPath or dirPath == "" then return {} end
    local models = {}

    local dirHandle = io.popen(string.format('dir "%s" /b /a:d', dirPath))
    if dirHandle then
        for folder in dirHandle:lines() do
            folder = _trim(folder)
            if folder ~= "" and folder ~= "." and folder ~= ".." and not folder:match("^%.") then
                local normalized = _normalizeModelName(folder)
                if normalized ~= "" then
                    _uniqueInsert(models, normalized)
                end
            end
        end
        dirHandle:close()
    end

    local fileHandle = io.popen(string.format('dir "%s" /b /a-d', dirPath))
    if fileHandle then
        for file in fileHandle:lines() do
            file = _trim(file)
            if file ~= "" and file ~= "." and file ~= ".." and not file:match("^%.") then
                local ext = string.lower(file:match("%.([^%.]+)$") or "")
                local modelName = _normalizeModelName(file)
                if modelName ~= "" then
                    if ext == "" or ext == "yft" or ext == "ydd" or ext == "ydr" or ext == "ytd" then
                        _uniqueInsert(models, modelName)
                    end
                end
            end
        end
        fileHandle:close()
    end

    table.sort(models, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    return models
end

-- Lắng nghe sự kiện yêu cầu đồng bộ danh sách xe từ Client
RegisterNetEvent('remove-npcs:requestVehicles')
AddEventHandler('remove-npcs:requestVehicles', function()
    local src = source
    
    -- Quét realtime từ Windows
    local noShopList = GetVehicleModels(pathNoShop)
    local shopList   = GetVehicleModels(pathShop)
    local nganhList  = GetVehicleModels(pathNganh) 

    -- Trả mảng dữ liệu mã xe cực sạch về cho client.lua vẽ giao diện
    TriggerClientEvent('remove-npcs:receiveVehicles', src, noShopList, shopList, nganhList)
end)