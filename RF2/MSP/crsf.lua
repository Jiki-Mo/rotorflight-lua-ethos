-- CRSF Devices
local CRSF_ADDRESS_BETAFLIGHT          = 0xC8
local CRSF_ADDRESS_RADIO_TRANSMITTER   = 0xEA

-- CRSF Frame Types
local CRSF_FRAMETYPE_MSP_REQ           = 0x7A      -- response request using msp sequence as command
local CRSF_FRAMETYPE_MSP_RESP          = 0x7B      -- reply with 60 byte chunked binary
local CRSF_FRAMETYPE_MSP_WRITE         = 0x7C      -- write with 60 byte chunked binary

local crsfMspCmd = 0

rf2.protocol.crsf = {}

if crsf.getSensor ~= nil then
    -- Ethos firmware >= 1.6.0
    local sensor = crsf.getSensor()
    rf2.protocol.crsf.popFrame = function() return sensor:popFrame() end
    rf2.protocol.crsf.pushFrame = function(x,y) return sensor:pushFrame(x,y) end
else
    -- Ethos firmware < 1.6.0
    rf2.protocol.crsf.popFrame = function() return crsf.popFrame() end
    rf2.protocol.crsf.pushFrame = function(x,y) return crsf.pushFrame(x,y) end
end

rf2.protocol.mspSend = function(payload)
    local payloadOut = { CRSF_ADDRESS_BETAFLIGHT, CRSF_ADDRESS_RADIO_TRANSMITTER }
    for i=1, #(payload) do
        payloadOut[i+2] = payload[i]
    end
    return rf2.protocol.crsf.pushFrame(crsfMspCmd, payloadOut)
end

rf2.protocol.mspRead = function(cmd)
    crsfMspCmd = CRSF_FRAMETYPE_MSP_REQ
    return rf2.mspCommon.mspSendRequest(cmd, {})
end

rf2.protocol.mspWrite = function(cmd, payload)
    crsfMspCmd = CRSF_FRAMETYPE_MSP_WRITE
    return rf2.mspCommon.mspSendRequest(cmd, payload)
end

rf2.protocol.mspPoll = function()
    while true do
        local cmd, data = rf2.protocol.crsf.popFrame()
        if cmd == CRSF_FRAMETYPE_MSP_RESP and data[1] == CRSF_ADDRESS_RADIO_TRANSMITTER and data[2] == CRSF_ADDRESS_BETAFLIGHT then
--[[
            rf2.print("cmd:0x"..string.format("%X", cmd))
            rf2.print("  data length: "..string.format("%u", #data))
            for i=1,#data do
                rf2.print("  ["..string.format("%u", i).."]:  0x"..string.format("%X", data[i]))
            end
--]]
            local mspData = {}
            for i = 3, #data do
                mspData[i - 2] = data[i]
            end
            return mspData
        elseif cmd == nil then
            return nil
        end
    end
end
