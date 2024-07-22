local framework = nil

RegisterNUICallback("ps-banking:client:getLocales", function(_, cb)
    cb(lib.getLocales())
end)

RegisterNUICallback("ps-banking:client:hideUI", function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback("ps-banking:client:phoneOption", function(_, cb)
    cb(Config.LBPhone)
end)

Citizen.CreateThread(function()
    local zoneId = 1
    for _, location in pairs(Config.BankLocations.Coords) do
        local zoneName = "bank_" .. zoneId
        exports["qb-target"]:AddBoxZone(zoneName, vector3(location.x, location.y, location.z), 1.5, 1.6, {
            name = zoneName,
            heading = 0.0,
            debugPoly = false,
            minZ = location.z - 1,
            maxZ = location.z + 1,
        }, {
            options = {
                {
                    icon = "fas fa-credit-card",
                    label = locale("openBank"),
                    action = function()
                        SendNUIMessage({
                            action = "openBank",
                        })
                        SetNuiFocus(true, true)
                    end,
                },
            },
            distance = 2.5,
        })
        zoneId = zoneId + 1
    end

    for i = 1, #Config.BankLocations.Coords do
        local blip = AddBlipForCoord(vector3(Config.BankLocations.Coords[i].x, Config.BankLocations.Coords[i].y,
            Config.BankLocations.Coords[i].z))
        SetBlipSprite(blip, Config.BankLocations.Blips.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.BankLocations.Blips.scale)
        SetBlipColour(blip, Config.BankLocations.Blips.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.BankLocations.Blips.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- ATM
function ATM_Animation()
    lib.requestAnimDict(Config.ATM_Animation.dict)
    TaskPlayAnim(PlayerPedId(), Config.ATM_Animation.dict, Config.ATM_Animation.name, 8.0, -8.0, -1,
        Config.ATM_Animation.flag, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(PlayerPedId())
end

exports["qb-target"]:AddTargetModel(Config.ATM_Models, {
    options = {
        {
            icon = "fas fa-solid fa-money-bills",
            label = locale("openATM"),
            action = function()
                ATM_Animation()
                SendNUIMessage({
                    action = "openATM",
                })
                SetNuiFocus(true, true)
            end,
        },
    },
    distance = 2.5,
})

if GetResourceState("es_extended") == "started" then
    framework = "ESX"
    ESX = exports["es_extended"]:getSharedObject()
elseif GetResourceState("qb-core") == "started" then
    framework = "QBCore"
    QBCore = exports["qb-core"]:GetCoreObject()
else
    return error(locale("no_framework_found"))
end

local function getPlayerAccounts()
    local accounts = {}
    if framework == "ESX" then
        accounts = ESX.GetPlayerData().accounts
    elseif framework == "QBCore" then
        accounts = QBCore.Functions.GetPlayerData().money
    end
    return accounts
end

RegisterNUICallback("ps-banking:client:getBills", function(data, cb)
    local success = lib.callback.await("ps-banking:server:getBills", false)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:payBill", function(data, cb)
    local success = lib.callback.await("ps-banking:server:payBill", false, data.id)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:getHistory", function(data, cb)
    local success = lib.callback.await("ps-banking:server:getHistory", false)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:deleteHistory", function(data, cb)
    local success = lib.callback.await("ps-banking:server:deleteHistory", false)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:payAllBills", function(data, cb)
    local success = lib.callback.await("ps-banking:server:payAllBills", false)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:getWeeklySummary", function(data, cb)
    local summary = lib.callback.await("ps-banking:server:getWeeklySummary", false)
    cb(summary)
end)

RegisterNUICallback("ps-banking:client:transferMoney", function(data, cb)
    local success, message = lib.callback.await("ps-banking:server:transferMoney", false, data)
    cb({
        success = success,
        message = message,
    })
end)

RegisterNUICallback("ps-banking:client:getTransactionStats", function(data, cb)
    local success = lib.callback.await("ps-banking:server:getTransactionStats", false)
    cb(success)
end)

if framework == "ESX" then
    RegisterNetEvent("esx:setAccountMoney", function(account)
        local moneyData = {}
        for k, v in pairs(getPlayerAccounts()) do
            table.insert(moneyData, {
                amount = v.money,
                name = v.name == "money" and "cash" or v.name,
            })
        end
        Wait(50)
        TriggerServerEvent("ps-banking:server:logClient", account, moneyData)
    end)
elseif framework == "QBCore" then
    RegisterNetEvent("QBCore:Client:OnMoneyChange", function(moneyType, amount)
        local moneyData = {}
        for k, v in pairs(getPlayerAccounts()) do
            table.insert(moneyData, {
                name = k,
                amount = v,
            })
        end
        Wait(50)
        TriggerServerEvent("ps-banking:server:logClient", {
            name = "bank",
            moneyType = moneyType,
            amount = amount,
        }, moneyData)
    end)
end

RegisterNUICallback("ps-banking:client:createNewAccount", function(data, cb)
    local success = lib.callback.await("ps-banking:server:createNewAccount", false, data.newAccount)
    cb({
        success = success,
    })
end)

RegisterNUICallback("ps-banking:client:getUser", function(data, cb)
    local success = lib.callback.await("ps-banking:server:getUser", false)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:getAccounts", function(data, cb)
    local success = lib.callback.await("ps-banking:server:getAccounts", false)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:deleteAccount", function(data, cb)
    local success = lib.callback.await("ps-banking:server:deleteAccount", false, data.accountId)
    cb({
        success = success,
    })
end)

RegisterNUICallback("ps-banking:client:withdrawFromAccount", function(data, cb)
    local success = lib.callback.await("ps-banking:server:withdrawFromAccount", false, data.accountId, data.amount)
    cb({
        success = success,
    })
end)

RegisterNUICallback("ps-banking:client:depositToAccount", function(data, cb)
    local success = lib.callback.await("ps-banking:server:depositToAccount", false, data.accountId, data.amount)
    cb({
        success = success,
    })
end)

RegisterNUICallback("ps-banking:client:addUserToAccount", function(data, cb)
    local success = lib.callback.await("ps-banking:server:addUserToAccount", false, data.accountId, data.userId)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:removeUserFromAccount", function(data, cb)
    local success = lib.callback.await("ps-banking:server:removeUserFromAccount", false, data.accountId, data.user)
    cb({
        success = success,
    })
end)

RegisterNUICallback("ps-banking:client:renameAccount", function(data, cb)
    local success = lib.callback.await("ps-banking:server:renameAccount", false, data.id, data.newName)
    cb({
        success = success,
    })
end)

RegisterNUICallback("ps-banking:client:copyAccountNumber", function(data, cb)
    lib.setClipboard(data.accountNumber)
    cb(true)
end)

RegisterNUICallback("ps-banking:client:ATMwithdraw", function(data, cb)
    local success = lib.callback.await("ps-banking:server:ATMwithdraw", false, data.amount)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:ATMdeposit", function(data, cb)
    local success = lib.callback.await("ps-banking:server:ATMdeposit", false, data.amount)
    cb(success)
end)

RegisterNUICallback("ps-banking:client:getMoneyTypes", function(data, cb)
    local moneyData = {}

    if framework == "ESX" then
        for k, v in pairs(getPlayerAccounts()) do
            table.insert(moneyData, {
                amount = v.money,
                name = v.name == "money" and "cash" or v.name,
            })
        end
    elseif framework == "QBCore" then
        local PlayerData = QBCore.Functions.GetPlayerData()
        for k, v in pairs(PlayerData.money) do
            table.insert(moneyData, {
                amount = v,
                name = k,
            })
        end
    end

    print(json.encode(moneyData))
    cb(moneyData)
end)

RegisterNUICallback("ps-banking:client:getAmountPresets", function(_, cb)
    cb(json.encode({
        withdrawAmounts = Config.PresetATM_Amounts.Amounts,
        depositAmounts = Config.PresetATM_Amounts.Amounts,
        grid = Config.PresetATM_Amounts.Grid,
    }))
end)
