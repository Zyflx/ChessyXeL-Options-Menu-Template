--[[
    For those reading this; This was meant to be a ChessyXeL test as i wanted to try and learn it
    This is a very simple options menu that makes use of ChessyXeL's "Save" class to store save data for the options
    Feel free to expand and/or improve on this if you'd like
    add option categories, whatever you want
    And yes, Setting the options actually changes them it's not just for show lmao
    And one more thing, this was made for actual psych engine options, if you want to add custom options, you'll need to modify the script to add support for custom options
    Also if you are going to build off of this script and release it, credit me for the base script
--]]

local Game = require 'ChessyXeL.Game';
local Save = require 'ChessyXeL.util.Save';
local Sprite = require 'ChessyXeL.display.Sprite';
local Stage = require 'ChessyXeL.Stage';
local Text = require 'ChessyXeL.display.text.Text';
local FieldStatus = require 'ChessyXeL.FieldStatus';
local Math = require 'ChessyXeL.math.Math';
local Group = require 'ChessyXeL.groups.Group';
-- local ClassObject = require 'ChessyXeL.display.object.ClassObject';

local settingList = {}; -- Gets set onCreate
local bgs = {'menuBG', 'menuDesat', 'menuBGBlue', 'menuBGMagenta'};

local SaveData = nil;
local Settings;

local settingTxt;
local textGroup;
local Arrow;

local curSelected = 1;

local folder, varthing;

Stage.set('onCreate', function()
    -- Make the other cams invisible
    Game.camGame.visible = false;
    Game.camHUD.visible = false;

    -- Backwards compatibility moment
    folder = (version ~= '0.7b' and '' or 'backend.');
    varthing = (version ~= '0.7b' and '' or 'data.');

    -- Add The Bg
    local optionsBG = Sprite(0, 0).loadGraphic(bgs[getRandomInt(1, #bgs - 1)]);
    optionsBG.camera = 'other';
    optionsBG.add();

    -- Play Music
    -- Would have used ChessyXeL's Sound class but there's no function to play music only sounds
    playMusic('offsetSong', 1, true);

    -- Initialize Settings
    initSettings();

    -- Add the options you added to the save data here
    -- Make sure you added the save data var for it first
    -- Go to the `initSettings()` function for more on adding options to the save data (can be found at the bottom the the script)
    settingList = {
        {'Downscroll', 'downScroll', Settings.downScroll}, -- Display Name, The ClientPrefs Variable, The Bool Value
        {'Middlescroll', 'middleScroll', Settings.middleScroll},
        {'Opponent Notes', 'opponentStrums', Settings.opponentStrums},
        {'Ghost Tapping', 'ghostTapping', Settings.ghostTapping},
        {'Disable Reset Button', 'noReset', Settings.noReset}
    };

    -- Thanks Cherry for telling me how to use ChessyXeL Groups properly you are a lifesaver
    textGroup = Group();

    -- Add the options text
    -- IT'S MADE WITH CHESSYXEL TEXT NOW LETS GOOOO
    for i = 1, #settingList do
        settingTxt = Text(40, 30 + (i * 100), 0, settingList[i][1] .. ': ' .. tostring(settingList[i][3]), 50, 0xFFFFFFFF, 'vcr.ttf');
        settingTxt.ID = i;
        settingTxt.camera = 'other';

        textGroup.order = i + 2;
        textGroup.add(settingTxt);
    end
    changeSelection(0);

    local Title = Text(0, 20, 0, 'ChessyXeL Options Menu Test', 50, 0xFFFFFFFF, 'vcr.ttf');
    Title.camera = 'other';
    Title.screenCenter('X');
    Title.add();

    local Message = Text(screenWidth - 1250, screenHeight - 50, 0, 'Press Enter To Toggle an Option | Press BACKSPACE To Exit.', 35, 0xFFFFFFFF, 'vcr.ttf');
    Message.camera = 'other';
    Message.add();

    Arrow = Text(5, textGroup.members[1].y, 0, '>', 50, 0xFFFFFFFF, 'vcr.ttf');
    Arrow.camera = 'other';
    Arrow.add();

    --[[makeLuaText('arrow', '>', 0, 5, getProperty(textGroup[1] .. '.y'));
    setTextSize('arrow', 50);
    setObjectCamera('arrow', 'other');
    addLuaText('arrow');]]
end);

Stage.set('onUpdate', function(elapsed)
    if (getProperty('controls.UI_UP_P')) then
        changeSelection(-1);
    elseif (getProperty('controls.UI_DOWN_P')) then
        changeSelection(1);
    end

    if (keyboardJustPressed('ENTER')) then
        toggleSetting();
    end

    local lerpVal = Math.bound(elapsed * 9.6, 0, 1);
    for i = 1, #textGroup.members do
        -- Only scroll the text if you have more than 6 options
        if (#textGroup.members > 6) then
            -- Me when i make a unnecessarily complex math equation just to do something simple
            textGroup.members[i].y = Math.lerp(textGroup.members[i].y,
            ((elapsed * 4) - (curSelected - 1) * 40 * 2 - 2 * (i * 8) + (i * 100)), lerpVal);

            -- Makes the option invisible when it goes off screen
            if (textGroup.members[i].y < screenHeight * 0.1 - 110) then
                textGroup.members[i].visible = false;
            else
                textGroup.members[i].visible = true;
            end
        end
    end

    -- Change the arrow's y position depending on what option is selected
    Arrow.y = textGroup.members[curSelected].y;
end);

Stage.set('onUpdatePost', function()
    if (keyboardJustPressed('BACKSPACE')) then
        exitSong();
    end
end);

function changeSelection(num)
    curSelected = curSelected + num;
    if (curSelected > #textGroup.members) then curSelected = 1; end
    if (curSelected < 1) then curSelected = #textGroup.members; end
        
    -- setProperty('arrow.y', getProperty(textGroup[curSelected] .. '.y'));

    for i = 1, #textGroup.members do
        if (curSelected == textGroup.members[i].ID) then
            textGroup.members[i].alpha = 1;
        else
            textGroup.members[i].alpha = 0.5;
        end
    end
    -- debugPrint(curSelected);
end

function toggleSetting()
    local value = settingList[curSelected][3];
    value = not value;
    settingList[curSelected][3] = value;
    textGroup.members[curSelected].text = settingList[curSelected][1] .. ': ' .. tostring(value);
    setPropertyFromClass(folder .. 'ClientPrefs', varthing .. settingList[curSelected][2], value);
end

function initSettings()
    if (SaveData == nil) then
        -- Changing the save path to the data folder so it doesn't save to ChessyXeL/saves
        Save.savePath = FieldStatus.PUBLIC('default', 'default', 'mods/ChessyXeL Settings Test/data');
        SaveData = Save('OptionsData');
    end

    -- You can add more options here
    SaveData.data.Settings = {
        downScroll = downscroll,
        middleScroll = middlescroll,
        opponentStrums = getPropertyFromClass(folder .. 'ClientPrefs', varthing .. 'opponentStrums'),
        ghostTapping = getPropertyFromClass(folder .. 'ClientPrefs', varthing .. 'ghostTapping'),
        noReset = getPropertyFromClass(folder .. 'ClientPrefs', varthing .. 'noReset')
    };
    Settings = SaveData.data.Settings;
    SaveData.flush();
end

function onStartCountdown()
    return Function_Stop;
end