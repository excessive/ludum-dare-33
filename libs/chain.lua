-- https://gist.github.com/airstruck/e4f11dc803848c158ca0
return function (routine)
    local routines = { routine }
    local function execute ()
        local phase = 0
        local run
        local function continue ()
            local targetPhase = phase + 1
            return function (...)
                if phase == targetPhase then
                    return run(...)
                end
            end
        end
        local function wait (...)
            phase = phase + 1
            return coroutine.yield(...)
        end
        run = coroutine.wrap(function ()
            for i = 1, #routines do
                routines[i](continue, wait)
                phase = phase + 1
            end
        end)

        run()
    end
    local function appendOrExecute (routine)
        if routine then
            routines[#routines + 1] = routine
            return appendOrExecute
        else
            execute()
        end
    end
    return appendOrExecute
end
