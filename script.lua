------------------------------------------------------------------
-- HRP CENTER DETECTOR (0 delay trigger)
------------------------------------------------------------------

local centerMargin = 2 -- very tight so it only triggers on HRP

local function DetectCenterRedPixel()

    if not ESP.Enabled or not ESP.HoldKeyActive then
        return
    end

    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    for _, data in pairs(ESP.Pixels) do

        if data.root and data.root.Parent then

            local pos, visible = Camera:WorldToViewportPoint(data.root.Position)

            if visible then

                local dx = math.abs(pos.X - centerX)
                local dy = math.abs(pos.Y - centerY)

                -- Only trigger when crosshair is on HRP
                if dx <= centerMargin and dy <= centerMargin then

                    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
                    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)

                    return
                end

            end
        end
    end
end
