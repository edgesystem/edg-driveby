local _SET_PLAYER_CAN_DO_DRIVE_BY = 0x6E8834B52EC20C77
local inVehicle = false
local shootEnabled = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if IsPedInAnyVehicle(ped, false) then
            HandleDriveBy(ped)
        else
            HandleExitVehicle(ped)
        end
    end
end)

function HandleDriveBy(ped)
    if not inVehicle then
        EnterVehicle(ped)
    end
    
    -- Checa se o jogador está tentando atirar
    if IsControlPressed(0, 24) then -- MOUSE1 (ataque)
        if not shootEnabled then
            shootEnabled = true
            SetWeaponAnimation(ped) -- Forçar animação de tiro
        end
    else
        shootEnabled = false
    end
    
    -- Libera controles de tiro/mira dentro do carro
    DisableControlAction(0, 24, false)  -- ataque (MOUSE1)
    DisableControlAction(0, 25, false)  -- mira (MOUSE2)
    DisableControlAction(0, 92, false)  -- shoot in car
    DisableControlAction(0, 106, false) -- melee alternate in car
end

function EnterVehicle(ped)
    inVehicle = true

    -- Habilita drive-by
    Citizen.InvokeNative(_SET_PLAYER_CAN_DO_DRIVE_BY, PlayerId(), true)

    -- Configura a munição infinita para a arma atual
    local currentWeapon = GetSelectedPedWeapon(ped)
    SetPedInfiniteAmmo(ped, true, currentWeapon)
    SetPedInfiniteAmmoClip(ped, true)

    -- Impede o jogo de “holster” automático
    SetPedConfigFlag(ped, 36, true) -- Desabilita troca de arma
    SetPedCanSwitchWeapon(ped, false)
end

function HandleExitVehicle(ped)
    if inVehicle then
        ExitVehicle(ped)
    end
end

function ExitVehicle(ped)
    inVehicle = false
    Citizen.InvokeNative(_SET_PLAYER_CAN_DO_DRIVE_BY, PlayerId(), false)

    -- Restaura a configuração original
    SetPedInfiniteAmmo(ped, false, 0)
    SetPedInfiniteAmmoClip(ped, false)
    SetPedConfigFlag(ped, 36, false)
    SetPedCanSwitchWeapon(ped, true)

    -- Recarrega arma, se necessário
    local currentWeapon = GetSelectedPedWeapon(ped)
    SetCurrentPedWeapon(ped, currentWeapon, true) -- Garante que a arma está pronta para ser usada.
end

function SetWeaponAnimation(ped)
    local animDict = "weapons@pistol@" -- Mude para o dicionário de animações da arma em uso
    local animName = "fire" -- Mude para a animação "fire" ou equivalente da arma

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false, false, false)
end

-- Comando opcional para reiniciar o combate no veículo.
RegisterCommand('toggleVehCombat', function()
    inVehicle = false -- Força reinicialização na próxima iteração
    QBCore.Functions.Notify('VehicleCombat reiniciado', 'info')
end)

-- Comando de depuração para checar o status do combate no veículo.
RegisterCommand('debugVehCombat', function()
    print("Status do combate no veículo: " .. tostring(inVehicle))
end)