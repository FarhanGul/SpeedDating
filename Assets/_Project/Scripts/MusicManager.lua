--!Type(ClientAndServer)

-- Events
local e_requestServerTime = Event.new("requestServerTime")
local e_sendServerTimeToClient = Event.new("sendServerTimeToClient")

-- Private
local trackLengths
local audioSources

function self:ServerAwake()
    e_requestServerTime:Connect(function(player)
        e_sendServerTimeToClient:FireClient(player,Time.time)
    end)
end

function self:ClientAwake()
    e_sendServerTimeToClient:Connect(function(serverTime)
        StartSyncedMusic(serverTime)
    end)

    Initialize()
    e_requestServerTime:FireServer()
end

function Initialize()
    trackLengths = {}
    audioSources = {}
    for i = 0 , self.transform.childCount - 1  do
        table.insert(audioSources,self.transform:GetChild(i):GetComponent(AudioSource))
        table.insert(trackLengths,audioSources[i+1].clip.length)
    end
end

function StartSyncedMusic(serverTime)
    local track,seek = GetTrackAndClipSeek(serverTime)
    PlayTrack(track,seek)
end

function PlayTrack(track,seek)
    audioSources[track].time = seek
    audioSources[track]:Play()
    Timer.new(trackLengths[track] - seek, function() 
        track += 1
        if(track > #audioSources) then track = 1 end
        PlayTrack(track, 0)
    end, false)
end

function GetTrackAndClipSeek(serverTime)
    -- Calculate the total duration of one complete loop
    local totalDuration = 0
    for i = 1, #trackLengths do
        totalDuration += trackLengths[i]
    end

    -- Find the position within the loop
    local positionInLoop = serverTime % totalDuration

    -- Find the current track and seek position
    local accumulatedTime = 0
    for i = 1, #trackLengths do
        if positionInLoop < accumulatedTime + trackLengths[i] then
            local seekPosition = positionInLoop - accumulatedTime
            return i, seekPosition
        end
        accumulatedTime = accumulatedTime + trackLengths[i]
    end
    -- Fallback (should never be reached if logic is correct)
    return 1, 0
end