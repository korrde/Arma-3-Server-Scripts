missionInProgress = false;
missionTime = 0;
maxMissionTime = 60;
missionCooldown = false;
lastMissionTime = -1;
cooldownDuration = 180;

fnc_spawnArtilleryModules = {
    params ["_marker"];
    
    private _artilleryClass = "ModuleOrdnanceHowitzer_F";
    private _spawnedModules = [];
    private _positions = [_marker, 15] call fnc_getRandomPositionsInMarker;
    
    {
        private _module = createVehicle [_artilleryClass, _x, [], 0, "CAN_COLLIDE"];
        _module setDir random 360;
        _spawnedModules pushBack _module;
        sleep 3;
    } forEach _positions;
    
    _spawnedModules
};

fnc_getRandomPositionsInMarker = {
    params ["_marker", "_count"];
    private _center = getMarkerPos _marker;
    private _size = getMarkerSize _marker;
    private _radius = (_size select 0) min (_size select 1);
    private _positions = [];
    
    for "_i" from 1 to _count do {
        private _angle = random 360;
        private _distance = sqrt(random 1) * _radius;
        private _x = (_center select 0) + (_distance * sin _angle);
        private _y = (_center select 1) + (_distance * cos _angle);
        _positions pushBack [_x, _y, 0];
    };
    
    _positions
};

fnc_getRandomPosInMarker = {
    params ["_marker"];
    private _center = getMarkerPos _marker;
    private _size = getMarkerSize _marker;
    private _radius = (_size select 0) min (_size select 1);
    
    private _angle = random 360;
    private _distance = sqrt(random 1) * _radius;
    
    private _x = (_center select 0) + (_distance * sin _angle);
    private _y = (_center select 1) + (_distance * cos _angle);
    
    [_x, _y, 0]
};

fnc_cleanCorpses = {
    private _markerPos = getMarkerPos "marker_139";
    private _radius = 4000;
    
    private _deadMen = allDeadMen select {
        (_x distance _markerPos) <= _radius
    };
    
    private _count = count _deadMen;
    
    if (_count > 0) then {
        systemChat format ["Начинаю удаление %1 трупов в зоне операции...", _count];
        
        {
            deleteVehicle _x;
            sleep 0.01;
        } forEach _deadMen;
        
        systemChat "Удаление трупов в зоне операции завершено.";
    } else {
        systemChat "Нет трупов для удаления в зоне операции.";
    };
};
[] spawn fnc_cleanCorpses;

fnc_createPatrol = {
    params ["_group", "_marker", "_wpCount"];
    
    for "_i" from 1 to _wpCount do {
        private _patrolPos = [_marker] call fnc_getRandomPosInMarker;
        private _wp = _group addWaypoint [_patrolPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointCompletionRadius 10;
        
        if (_i == _wpCount) then {
            _wp setWaypointType "CYCLE";
        };
    };
    
    _group setBehaviour "SAFE";
    _group setSpeedMode "LIMITED";
};

fnc_spawnSquad = {
    params ["_marker", "_unitClasses", "_skill"];
    
    private _grp = createGroup [east, true];
    
    {
        private _randomPos = [_marker] call fnc_getRandomPosInMarker;
        private _safePos = [_randomPos, 0, 30, 1, 0, 0.5, 0] call BIS_fnc_findSafePos;
        if (count _safePos == 2) then { _randomPos = _safePos };
        
        private _unit = _grp createUnit [_x, _randomPos, [], 0, "NONE"];
        _unit setSkill _skill;
        sleep 0.05;
    } forEach _unitClasses;

    [_grp, _marker, 3 + floor(random 3)] call fnc_createPatrol;
};

fnc_spawnSingleVehicle = {
    params ["_marker", "_vehicleClass"];
    
    private _randomPos = [_marker] call fnc_getRandomPosInMarker;
    private _safePos = [_randomPos, 0, 30, 5, 0, 0.7, 0] call BIS_fnc_findSafePos;
    if (count _safePos == 2) then { _randomPos = _safePos };
    
    private _isFlyingVehicle = _vehicleClass == "3AS_HMP_Gunship";
    if (_isFlyingVehicle) then {
        _randomPos set [2, 20];
    };
    private _vehicle = createVehicle [
        _vehicleClass, 
        _randomPos, 
        [], 
        0, 
        if (_isFlyingVehicle) then { "FLY" } else { "NONE" }
    ];
    createVehicleCrew _vehicle;
    private _group = group (driver _vehicle);
    if (_isFlyingVehicle) then {
        _vehicle flyInHeight 50;
        _vehicle setVehicleAmmo 1;
        _vehicle setFuel 1;
        _vehicle engineOn true;

        {
            _x setSkill ["courage", 1];
            _x setSkill ["commanding", 1];
            _x setSkill ["spotDistance", 1];
        } forEach (crew _vehicle);
    };

    private _wpCount = 2 + floor(random 2);
    
    for "_i" from 1 to _wpCount do {
        private _patrolPos = [_marker] call fnc_getRandomPosInMarker;
        
        if (_isFlyingVehicle) then {
            _patrolPos set [2, 50 + random 30];
        };
        
        private _wp = _group addWaypoint [_patrolPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointCompletionRadius 50;
        
        if (_i == _wpCount) then {
            _wp setWaypointType "CYCLE";
        };
    };
    
    _group setBehaviour "COMBAT";
    _group setSpeedMode "NORMAL";
    [_group, _marker] spawn {
        params ["_group", "_marker"];
        while {true} do {
            sleep 30;
            if (leader _group distance (getMarkerPos _marker) > (getMarkerSize _marker select 0)) then {
                private _newPos = [_marker] call fnc_getRandomPosInMarker;
                _newPos set [2, 50 + random 30];
                _group move _newPos;
            };
        };
    };
    
    sleep 0.1;
};

fnc_spawnEnemies = {
    params ["_marker"];
    
    for "_i" from 1 to 4 do {
        [_marker, "3AS_AAT"] call fnc_spawnSingleVehicle;
        sleep 0.1;
    };
    for "_i" from 1 to 2 do {
        [_marker, "3AS_AAT_Red"] call fnc_spawnSingleVehicle;
        sleep 0.1;
    };
    for "_i" from 1 to 2 do {
        [_marker, "3AS_AAT_Red"] call fnc_spawnSingleVehicle;
        sleep 0.1;
    };
    for "_i" from 1 to 1 do {
        [_marker, "3AS_MTT"] call fnc_spawnSingleVehicle;
        sleep 0.1;
    };
    for "_i" from 1 to 2 do {
        [_marker, "3AS_Advanced_DSD"] call fnc_spawnSingleVehicle;
        sleep 0.1;
    };
    for "_i" from 1 to 2 do {
        [_marker, "3AS_HMP_Gunship"] call fnc_spawnSingleVehicle;
        sleep 0.1;
    };    
    for "_i" from 1 to 30 do {
        private _units = ["lsd_cis_b1_standard", "lsd_cis_b1_standard", "lsd_cis_b1_standard"];
        [_marker, _units, 0.3] call fnc_spawnSquad;
        sleep 0.5;
    };
    for "_i" from 1 to 5 do {
        private _count = if (_i == 3) then {4} else {3};
        private _units = [];
        for "_j" from 1 to _count do {
            _units pushBack "3AS_CIS_B2_F";
        };
        [_marker, _units, 0.6] call fnc_spawnSquad;
        sleep 0.5;
    };
    systemChat "Спавн всех юнитов завершен";
};

fnc_checkCooldown = {
    private _timeSinceLastMission = (serverTime - lastMissionTime) / 60;
    if (_timeSinceLastMission < cooldownDuration) then {
        private _remainingTime = cooldownDuration - _timeSinceLastMission;
        hint format ["Задачу можно будет взять через %1 минут", round _remainingTime];
        systemChat format ["Кулдаун: %1 минут до следующей миссии", round _remainingTime];
        false
    } else {
        true
    };
};

fnc_startMission = {
    params ["_target"];
    
    if (missionInProgress) exitWith { hint "Миссия уже выполняется!"; };
    if (lastMissionTime >= 0 && {(serverTime - lastMissionTime) / 60 < cooldownDuration}) then {
        private _remainingTime = cooldownDuration - ((serverTime - lastMissionTime) / 60);
        hint format ["Задачу можно будет взять через %1 минут", round _remainingTime];
        systemChat format ["Кулдаун: %1 минут до следующей миссии", round _remainingTime];
        false
    } else {
        missionInProgress = true;
        missionTime = 0;
        
        ["marker_139"] call fnc_spawnEnemies;
        
        [] spawn {
            for "_i" from 1 to 4 do {
                sleep (15 * 60);
                ["marker_139"] call fnc_spawnEnemies;
                missionTime = missionTime + 20;
                systemChat format["Прошло %1 минут. Волна врагов #%2", missionTime, _i+1];
            };

            sleep (15 * 60);
            missionInProgress = false;
            lastMissionTime = serverTime;
            hint "Миссия в красной зоне завершена. Спавн врагов прекращен. Кулдаун начался.";
        };

        [] spawn {
            while {missionInProgress} do {
                sleep (30 * 60);
                [] spawn fnc_cleanCorpses;
            };
        };
        
        hint "Задача начата! Враги патрулируют красную зону. Миссия продлится 60 минут.";
        systemChat "Трупы будут автоматически удаляться каждые 30 минут.";
        true
    };
};

[] spawn {
    private _artilleryModules = [];
    private _nextSpawnTime = -1;
    private _missionStartTime = -1;
    private _maxMissionDuration = 60 * 60;
    
    while {true} do {
        if (!isNil "penis" && {!isNull penis}) then {
            removeAllActions penis;
            if (!missionInProgress && (lastMissionTime < 0 || (serverTime - lastMissionTime) / 60 >= cooldownDuration)) then {
                penis addAction [
                    "Взять задачу (Красная зона)", 
                    {
                        [_this select 0] call fnc_startMission;
                        _missionStartTime = serverTime;
                        _nextSpawnTime = _missionStartTime + (20 * 60);
                    },
                    nil,
                    1.5,
                    true,
                    true,
                    "",
                    "!missionInProgress && (lastMissionTime < 0 || (serverTime - lastMissionTime) / 60 >= cooldownDuration)",
                    5
                ];
            };
            
            // арта
            if (missionInProgress && _missionStartTime != -1) then {
                if ((serverTime - _missionStartTime) >= _maxMissionDuration) then {
                    missionInProgress = false;
                    lastMissionTime = serverTime;
                    _nextSpawnTime = -1;
                    _missionStartTime = -1;
                };
                if (serverTime >= _nextSpawnTime && (serverTime - _missionStartTime) < _maxMissionDuration) then {
                    if (random 1 < 0.4) then {
                        { deleteVehicle _x } forEach (_artilleryModules select {!isNull _x});
                        _artilleryModules = [];
                        [] spawn {
                            private _newModules = ["marker_139"] call fnc_spawnArtilleryModules;
                            systemChat "ЛЕТИТ АРТИЛЛЕРИЯ ПРОТИВНИКА. НАЙДИТЕ УКРЫТИЕ. СРОЧНО!";
                            _artilleryModules append _newModules;
                            systemChat "АРТИЛЛЕРИЯ ЗАКОНЧИЛА РАБОТУ. В БОЙ! ЗА РЕСПУБЛИКУ!";
                        };
                    } else {
                        systemChat "Артиллерийский огонь не замечен. Продолжайте наступление в том же темпе.";
                    };
                    
                    _nextSpawnTime = serverTime + (20 * 60);
                };
            } else {
                { deleteVehicle _x } forEach (_artilleryModules select {!isNull _x});
                _artilleryModules = [];
            };
            
            waitUntil {
                sleep 5;
                missionInProgress || (lastMissionTime >= 0 && (serverTime - lastMissionTime) / 60 < cooldownDuration) || isNull penis
            };
        } else {
            sleep 5;
        };
    };
};