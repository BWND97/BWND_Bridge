Bridge = Bridge or {}

local function normaliseQbGroup(group)
    if type(group) ~= 'table' then return nil end
    local grade = group.grade
    local gradeLevel, gradeName, gradeBoss
    if type(grade) == 'table' then
        gradeLevel = tonumber(grade.level) or 0
        gradeName = grade.name
        gradeBoss = grade.isboss == true
    else
        gradeLevel = tonumber(grade) or 0
        gradeName = group.grade_name
        gradeBoss = group.isboss == true
    end
    return {
        name = group.name,
        label = group.label,
        type = group.type,
        salary = group.payment or group.salary or 0,
        onduty = group.onduty == nil and true or group.onduty,
        isboss = group.isboss == true or gradeBoss,
        grade = { name = gradeName or ('Grade ' .. gradeLevel), level = gradeLevel, isboss = gradeBoss },
    }
end

local function normaliseEsxJob(job)
    if type(job) ~= 'table' then return nil end
    local level = tonumber(job.grade) or 0
    local onduty = job.onDuty
    if onduty == nil then onduty = job.onduty end
    if onduty == nil then onduty = true end
    return {
        name = job.name,
        label = job.label,
        type = job.type,
        salary = job.salary or job.payment or 0,
        onduty = onduty == true,
        isboss = false,
        grade = {
            name = job.grade_name or job.grade_label or ('Grade ' .. level),
            level = level,
            isboss = false,
        },
    }
end

function Bridge.GetJob(id)
    local p = Bridge._getPlayerObject(id)
    if not p then return nil end
    if p.PlayerData then return normaliseQbGroup(p.PlayerData.job) end
    return normaliseEsxJob(p.job)
end

function Bridge.GetGang(id)
    local p = Bridge._getPlayerObject(id)
    if not p or not p.PlayerData then return nil end
    return normaliseQbGroup(p.PlayerData.gang)
end

function Bridge.GetJobGrade(jobOrId)
    if type(jobOrId) == 'table' then
        local g = jobOrId.grade
        if type(g) == 'table' then return tonumber(g.level) or 0 end
        return tonumber(g) or 0
    end
    local job = Bridge.GetJob(jobOrId)
    return job and job.grade.level or 0
end

function Bridge.SetJob(id, name, grade)
    grade = tonumber(grade) or 0
    if Bridge.Framework == 'qbx' then
        return (QBX and QBX:SetJob(id, name, grade)) ~= false
    elseif Bridge.Framework == 'qb' then
        local p = Bridge._getPlayerObject(id)
        return p ~= nil and p.Functions.SetJob(name, grade) ~= false
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        p.setJob(name, grade)
        return true
    end
    return false
end

function Bridge.SetGang(id, name, grade)
    grade = tonumber(grade) or 0
    if Bridge.Framework == 'qbx' then
        return (QBX and QBX:SetGang(id, name, grade)) ~= false
    elseif Bridge.Framework == 'qb' then
        local p = Bridge._getPlayerObject(id)
        return p ~= nil and p.Functions.SetGang(name, grade) ~= false
    end
    return false
end

function Bridge.SetJobDuty(id, onDuty)
    onDuty = onDuty == true
    if Bridge.Framework == 'qbx' then
        return (QBX and QBX:SetJobDuty(id, onDuty)) ~= false
    elseif Bridge.Framework == 'qb' then
        local p = Bridge._getPlayerObject(id)
        return p ~= nil and p.Functions.SetJobDuty(onDuty) ~= false
    elseif Bridge.Framework == 'esx' then
        local job = Bridge.GetJob(id)
        if not job then return false end
        return Bridge.SetJob(id, job.name, job.grade.level)
    end
    return false
end

function Bridge.IsOnDuty(id)
    local job = Bridge.GetJob(id)
    return job ~= nil and job.onduty == true
end

function Bridge.GetJobs()
    if Bridge.Framework == 'qbx' then return QBX and QBX:GetJobs() or {} end
    if Bridge.Framework == 'qb' then return QBCore and QBCore.Shared.Jobs or {} end
    if Bridge.Framework == 'esx' then return ESX and ESX.GetJobs() or {} end
    return {}
end

function Bridge.GetGangs()
    if Bridge.Framework == 'qbx' then return QBX and QBX:GetGangs() or {} end
    if Bridge.Framework == 'qb' then return QBCore and QBCore.Shared.Gangs or {} end
    return {}
end

function Bridge.GetGroupGrades(groupType, name)
    if type(name) ~= 'string' or name == '' then return {} end
    local def
    if groupType == 'gang' then
        def = Bridge.GetGangs()[name]
    else
        def = Bridge.GetJobs()[name]
    end
    if type(def) ~= 'table' or type(def.grades) ~= 'table' then return {} end

    local grades = {}
    for level, data in pairs(def.grades) do
        local numeric = tonumber(level)
        if numeric then
            grades[#grades + 1] = {
                level = numeric,
                name = (type(data) == 'table' and (data.name or data.label)) or ('Grade ' .. numeric),
                isboss = type(data) == 'table' and data.isboss == true,
            }
        end
    end
    table.sort(grades, function(a, b) return a.level < b.level end)
    return grades
end

function Bridge.CountPlayersWithJob(jobName, onDutyOnly)
    local n = 0
    for _, src in ipairs(Bridge.GetPlayers()) do
        local job = Bridge.GetJob(src)
        if job and Bridge.NamesMatch(job.name, jobName) and (not onDutyOnly or job.onduty) then
            n = n + 1
        end
    end
    return n
end
