gdjs.Mine3DCode = {};
gdjs.Mine3DCode.localVariables = [];
gdjs.Mine3DCode.idToCallbackMap = new Map();
gdjs.Mine3DCode.GDGroundObjects1= [];
gdjs.Mine3DCode.GDGroundObjects2= [];
gdjs.Mine3DCode.GDGroundObjects3= [];
gdjs.Mine3DCode.GDGroundObjects4= [];
gdjs.Mine3DCode.GDPlayerObjects1= [];
gdjs.Mine3DCode.GDPlayerObjects2= [];
gdjs.Mine3DCode.GDPlayerObjects3= [];
gdjs.Mine3DCode.GDPlayerObjects4= [];
gdjs.Mine3DCode.GDObstacleObjects1= [];
gdjs.Mine3DCode.GDObstacleObjects2= [];
gdjs.Mine3DCode.GDObstacleObjects3= [];
gdjs.Mine3DCode.GDObstacleObjects4= [];
gdjs.Mine3DCode.GDCoinObjects1= [];
gdjs.Mine3DCode.GDCoinObjects2= [];
gdjs.Mine3DCode.GDCoinObjects3= [];
gdjs.Mine3DCode.GDCoinObjects4= [];
gdjs.Mine3DCode.GDPushableBoxObjects1= [];
gdjs.Mine3DCode.GDPushableBoxObjects2= [];
gdjs.Mine3DCode.GDPushableBoxObjects3= [];
gdjs.Mine3DCode.GDPushableBoxObjects4= [];
gdjs.Mine3DCode.GDJoystickObjects1= [];
gdjs.Mine3DCode.GDJoystickObjects2= [];
gdjs.Mine3DCode.GDJoystickObjects3= [];
gdjs.Mine3DCode.GDJoystickObjects4= [];
gdjs.Mine3DCode.GDJumpButtonObjects1= [];
gdjs.Mine3DCode.GDJumpButtonObjects2= [];
gdjs.Mine3DCode.GDJumpButtonObjects3= [];
gdjs.Mine3DCode.GDJumpButtonObjects4= [];
gdjs.Mine3DCode.GDControlsToggleObjects1= [];
gdjs.Mine3DCode.GDControlsToggleObjects2= [];
gdjs.Mine3DCode.GDControlsToggleObjects3= [];
gdjs.Mine3DCode.GDControlsToggleObjects4= [];
gdjs.Mine3DCode.GDMineBlockObjects1= [];
gdjs.Mine3DCode.GDMineBlockObjects2= [];
gdjs.Mine3DCode.GDMineBlockObjects3= [];
gdjs.Mine3DCode.GDMineBlockObjects4= [];
gdjs.Mine3DCode.GDPickaxeButtonObjects1= [];
gdjs.Mine3DCode.GDPickaxeButtonObjects2= [];
gdjs.Mine3DCode.GDPickaxeButtonObjects3= [];
gdjs.Mine3DCode.GDPickaxeButtonObjects4= [];
gdjs.Mine3DCode.GDOreHUDObjects1= [];
gdjs.Mine3DCode.GDOreHUDObjects2= [];
gdjs.Mine3DCode.GDOreHUDObjects3= [];
gdjs.Mine3DCode.GDOreHUDObjects4= [];
gdjs.Mine3DCode.GDPickaxeLabelObjects1= [];
gdjs.Mine3DCode.GDPickaxeLabelObjects2= [];
gdjs.Mine3DCode.GDPickaxeLabelObjects3= [];
gdjs.Mine3DCode.GDPickaxeLabelObjects4= [];
gdjs.Mine3DCode.GDMineHintObjects1= [];
gdjs.Mine3DCode.GDMineHintObjects2= [];
gdjs.Mine3DCode.GDMineHintObjects3= [];
gdjs.Mine3DCode.GDMineHintObjects4= [];


gdjs.Mine3DCode.eventsList0 = function(runtimeScene) {

{


let isConditionTrue_0 = false;
{
gdjs.copyArray(runtimeScene.getObjects("ControlsToggle"), gdjs.Mine3DCode.GDControlsToggleObjects1);
gdjs.copyArray(runtimeScene.getObjects("Joystick"), gdjs.Mine3DCode.GDJoystickObjects1);
gdjs.copyArray(runtimeScene.getObjects("JumpButton"), gdjs.Mine3DCode.GDJumpButtonObjects1);
gdjs.copyArray(runtimeScene.getObjects("MineHint"), gdjs.Mine3DCode.GDMineHintObjects1);
gdjs.copyArray(runtimeScene.getObjects("OreHUD"), gdjs.Mine3DCode.GDOreHUDObjects1);
gdjs.copyArray(runtimeScene.getObjects("PickaxeButton"), gdjs.Mine3DCode.GDPickaxeButtonObjects1);
gdjs.copyArray(runtimeScene.getObjects("PickaxeLabel"), gdjs.Mine3DCode.GDPickaxeLabelObjects1);
{for(var i = 0, len = gdjs.Mine3DCode.GDControlsToggleObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDControlsToggleObjects1[i].setPosition(32,32);
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDJoystickObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJoystickObjects1[i].setPosition(170,gdjs.evtTools.window.getGameResolutionHeight(runtimeScene) - 144);
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDJumpButtonObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJumpButtonObjects1[i].setPosition(gdjs.evtTools.window.getGameResolutionWidth(runtimeScene) - 176,gdjs.evtTools.window.getGameResolutionHeight(runtimeScene) - 144);
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDPickaxeButtonObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPickaxeButtonObjects1[i].setPosition(gdjs.evtTools.window.getGameResolutionWidth(runtimeScene) - 176,gdjs.evtTools.window.getGameResolutionHeight(runtimeScene) - 290);
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDPickaxeLabelObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPickaxeLabelObjects1[i].setPosition(gdjs.evtTools.window.getGameResolutionWidth(runtimeScene) - 238,gdjs.evtTools.window.getGameResolutionHeight(runtimeScene) - 232);
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDOreHUDObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDOreHUDObjects1[i].setPosition(Math.max(16, gdjs.evtTools.window.getGameResolutionWidth(runtimeScene) - (gdjs.Mine3DCode.GDOreHUDObjects1[i].getWidth()) - 24),28);
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDMineHintObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDMineHintObjects1[i].setPosition(Math.max(16, gdjs.evtTools.window.getGameResolutionWidth(runtimeScene) / 2 - (gdjs.Mine3DCode.GDMineHintObjects1[i].getWidth()) / 2),28);
}
}
}

}


};gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDMineBlockObjects2Objects = Hashtable.newFrom({"MineBlock": gdjs.Mine3DCode.GDMineBlockObjects2});
gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDPlayerObjects2Objects = Hashtable.newFrom({"Player": gdjs.Mine3DCode.GDPlayerObjects2});
gdjs.Mine3DCode.eventsList1 = function(runtimeScene) {

{

/* Reuse gdjs.Mine3DCode.GDMineBlockObjects2 */

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
for (var i = 0, k = 0, l = gdjs.Mine3DCode.GDMineBlockObjects2.length;i<l;++i) {
    if ( gdjs.Mine3DCode.GDMineBlockObjects2[i].getVariableNumber(gdjs.Mine3DCode.GDMineBlockObjects2[i].getVariables().getFromIndex(0)) <= 0 ) {
        isConditionTrue_0 = true;
        gdjs.Mine3DCode.GDMineBlockObjects2[k] = gdjs.Mine3DCode.GDMineBlockObjects2[i];
        ++k;
    }
}
gdjs.Mine3DCode.GDMineBlockObjects2.length = k;
if (isConditionTrue_0) {
/* Reuse gdjs.Mine3DCode.GDMineBlockObjects2 */
{runtimeScene.getScene().getVariables().getFromIndex(3).add(1);
}
{gdjs.evtTools.sound.playSound(runtimeScene, "assets/CoinPickUp.wav", false, 75, 1);
}
{for(var i = 0, len = gdjs.Mine3DCode.GDMineBlockObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDMineBlockObjects2[i].deleteFromScene(runtimeScene);
}
}
}

}


};gdjs.Mine3DCode.eventsList2 = function(runtimeScene) {

{

gdjs.copyArray(runtimeScene.getObjects("MineBlock"), gdjs.Mine3DCode.GDMineBlockObjects2);
gdjs.copyArray(runtimeScene.getObjects("PickaxeButton"), gdjs.Mine3DCode.GDPickaxeButtonObjects2);
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
for (var i = 0, k = 0, l = gdjs.Mine3DCode.GDPickaxeButtonObjects2.length;i<l;++i) {
    if ( gdjs.Mine3DCode.GDPickaxeButtonObjects2[i].getBehavior("MultitouchButton").IsJustPressed(null) ) {
        isConditionTrue_0 = true;
        gdjs.Mine3DCode.GDPickaxeButtonObjects2[k] = gdjs.Mine3DCode.GDPickaxeButtonObjects2[i];
        ++k;
    }
}
gdjs.Mine3DCode.GDPickaxeButtonObjects2.length = k;
if (isConditionTrue_0) {
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtsExt__Collision3D__AreWithinDistance.func(runtimeScene, gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDMineBlockObjects2Objects, gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDPlayerObjects2Objects, 155, true, null);
if (isConditionTrue_0) {
isConditionTrue_0 = false;
{isConditionTrue_0 = (runtimeScene.getScene().getVariables().getFromIndex(3).getAsNumber() < gdjs.evtTools.variable.getVariableNumber(runtimeScene.getScene().getVariables().getFromIndex(4)));
}
}
}
if (isConditionTrue_0) {
/* Reuse gdjs.Mine3DCode.GDMineBlockObjects2 */
{for(var i = 0, len = gdjs.Mine3DCode.GDMineBlockObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDMineBlockObjects2[i].returnVariable(gdjs.Mine3DCode.GDMineBlockObjects2[i].getVariables().getFromIndex(0)).sub(1);
}
}

{ //Subevents
gdjs.Mine3DCode.eventsList1(runtimeScene);} //End of subevents
}

}


{


let isConditionTrue_0 = false;
{
gdjs.copyArray(runtimeScene.getObjects("OreHUD"), gdjs.Mine3DCode.GDOreHUDObjects1);
{for(var i = 0, len = gdjs.Mine3DCode.GDOreHUDObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDOreHUDObjects1[i].setString("РУДА: " + gdjs.evtTools.common.toString(gdjs.evtTools.variable.getVariableNumber(runtimeScene.getScene().getVariables().getFromIndex(3))) + "/" + gdjs.evtTools.common.toString(gdjs.evtTools.variable.getVariableNumber(runtimeScene.getScene().getVariables().getFromIndex(4))));
}
}
}

}


};gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDCoinObjects2Objects = Hashtable.newFrom({"Coin": gdjs.Mine3DCode.GDCoinObjects2});
gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDPlayerObjects2Objects = Hashtable.newFrom({"Player": gdjs.Mine3DCode.GDPlayerObjects2});
gdjs.Mine3DCode.eventsList3 = function(runtimeScene) {

{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.runtimeScene.getTimerElapsedTimeInSecondsOrNaN(runtimeScene, "Coin_PitchTimer") > 1;
if (isConditionTrue_0) {
{runtimeScene.getScene().getVariables().getFromIndex(2).setNumber(gdjs.randomFloatInRange(0.9, 1.1));
}
{gdjs.evtTools.runtimeScene.removeTimer(runtimeScene, "Coin_PitchTimer");
}
}

}


{

gdjs.copyArray(runtimeScene.getObjects("Coin"), gdjs.Mine3DCode.GDCoinObjects2);
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtsExt__Collision3D__AreWithinDistance.func(runtimeScene, gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDCoinObjects2Objects, gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDPlayerObjects2Objects, 50, true, null);
if (isConditionTrue_0) {
/* Reuse gdjs.Mine3DCode.GDCoinObjects2 */
{for(var i = 0, len = gdjs.Mine3DCode.GDCoinObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDCoinObjects2[i].deleteFromScene(runtimeScene);
}
}
{gdjs.evtTools.sound.playSound(runtimeScene, "assets/CoinPickUp.wav", false, 100, runtimeScene.getScene().getVariables().getFromIndex(2).getAsNumber());
}
{gdjs.evtTools.runtimeScene.resetTimer(runtimeScene, "Coin_PitchTimer");
}
{runtimeScene.getScene().getVariables().getFromIndex(2).add(gdjs.randomWithStep(0.050, 0.1, 0.025));
}
}

}


{


let isConditionTrue_0 = false;
{
gdjs.copyArray(runtimeScene.getObjects("Coin"), gdjs.Mine3DCode.GDCoinObjects1);
{for(var i = 0, len = gdjs.Mine3DCode.GDCoinObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDCoinObjects1[i].rotate(35, runtimeScene);
}
}
}

}


};gdjs.Mine3DCode.eventsList4 = function(runtimeScene) {

{

gdjs.copyArray(gdjs.Mine3DCode.GDControlsToggleObjects1, gdjs.Mine3DCode.GDControlsToggleObjects2);


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
for (var i = 0, k = 0, l = gdjs.Mine3DCode.GDControlsToggleObjects2.length;i<l;++i) {
    if ( gdjs.Mine3DCode.GDControlsToggleObjects2[i].IsChecked(null) ) {
        isConditionTrue_0 = true;
        gdjs.Mine3DCode.GDControlsToggleObjects2[k] = gdjs.Mine3DCode.GDControlsToggleObjects2[i];
        ++k;
    }
}
gdjs.Mine3DCode.GDControlsToggleObjects2.length = k;
if (isConditionTrue_0) {
gdjs.copyArray(runtimeScene.getObjects("JumpButton"), gdjs.Mine3DCode.GDJumpButtonObjects2);
{runtimeScene.getScene().getVariables().getFromIndex(0).setString("Touch");
}
{for(var i = 0, len = gdjs.Mine3DCode.GDJumpButtonObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJumpButtonObjects2[i].hide(false);
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDJumpButtonObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJumpButtonObjects2[i].activateBehavior("MultitouchButton", true);
}
}
}

}


{

/* Reuse gdjs.Mine3DCode.GDControlsToggleObjects1 */

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
for (var i = 0, k = 0, l = gdjs.Mine3DCode.GDControlsToggleObjects1.length;i<l;++i) {
    if ( !(gdjs.Mine3DCode.GDControlsToggleObjects1[i].IsChecked(null)) ) {
        isConditionTrue_0 = true;
        gdjs.Mine3DCode.GDControlsToggleObjects1[k] = gdjs.Mine3DCode.GDControlsToggleObjects1[i];
        ++k;
    }
}
gdjs.Mine3DCode.GDControlsToggleObjects1.length = k;
if (isConditionTrue_0) {
gdjs.copyArray(runtimeScene.getObjects("JumpButton"), gdjs.Mine3DCode.GDJumpButtonObjects1);
{runtimeScene.getScene().getVariables().getFromIndex(0).setString("Keyboard");
}
{for(var i = 0, len = gdjs.Mine3DCode.GDJumpButtonObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJumpButtonObjects1[i].hide();
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDJumpButtonObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJumpButtonObjects1[i].activateBehavior("MultitouchButton", false);
}
}
}

}


};gdjs.Mine3DCode.eventsList5 = function(runtimeScene) {

{

gdjs.copyArray(runtimeScene.getObjects("ControlsToggle"), gdjs.Mine3DCode.GDControlsToggleObjects1);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
for (var i = 0, k = 0, l = gdjs.Mine3DCode.GDControlsToggleObjects1.length;i<l;++i) {
    if ( gdjs.Mine3DCode.GDControlsToggleObjects1[i].HasJustBeenToggled(null) ) {
        isConditionTrue_0 = true;
        gdjs.Mine3DCode.GDControlsToggleObjects1[k] = gdjs.Mine3DCode.GDControlsToggleObjects1[i];
        ++k;
    }
}
gdjs.Mine3DCode.GDControlsToggleObjects1.length = k;
if (isConditionTrue_0) {

{ //Subevents
gdjs.Mine3DCode.eventsList4(runtimeScene);} //End of subevents
}

}


};gdjs.Mine3DCode.eventsList6 = function(runtimeScene) {

{


let isConditionTrue_0 = false;
{
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("Object3D").setRotationY(gdjs.evtTools.common.clamp((gdjs.Mine3DCode.GDPlayerObjects2[i].getRotationY()), -90, 90));
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetElevationAngleOffset(gdjs.evtTools.common.clamp((gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").ElevationAngleOffset(null)), -90, 90), null);
}
}
}

}


{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtsExt__MousePointerLock__isPointerLocked.func(runtimeScene, null);
if (isConditionTrue_0) {
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtsExt__MousePointerLock__IsMoving.func(runtimeScene, null);
}
if (isConditionTrue_0) {
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetCameraRotation(gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").RotationAngle(null) + (180 * gdjs.evtsExt__MousePointerLock__MovementX.func(runtimeScene, null) / gdjs.evtTools.window.getGameResolutionWidth(runtimeScene)), null);
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetElevationAngleOffset(gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").ElevationAngleOffset(null) + (90 * gdjs.evtsExt__MousePointerLock__MovementY.func(runtimeScene, null) / gdjs.evtTools.window.getGameResolutionHeight(runtimeScene)), null);
}
}
{runtimeScene.getScene().getVariables().getFromIndex(1).setBoolean(true);
}
}

}


{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{isConditionTrue_0 = runtimeScene.getScene().getVariables().getFromIndex(1).getAsBoolean();
}
if (isConditionTrue_0) {
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetRotationHalfwayDuration(1000000, null);
}
}
}

}


{


let isConditionTrue_0 = false;
{
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetTargetedRotationAngle((gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("PhysicsCharacter3D").getForwardAngle()), null);
}
}
}

}


{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{let isConditionTrue_1 = false;
isConditionTrue_0 = false;
{
isConditionTrue_1 = gdjs.evtTools.input.isKeyPressed(runtimeScene, "s");
if(isConditionTrue_1) {
    isConditionTrue_0 = true;
}
}
{
{isConditionTrue_1 = (Math.abs(gdjs.evtTools.common.angleDifference(90, gdjs.evtsExt__SpriteMultitouchJoystick__StickAngle.func(runtimeScene, 1, "Primary", null))) < 90);
}
if(isConditionTrue_1) {
    isConditionTrue_0 = true;
}
}
{
}
}
if (isConditionTrue_0) {
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetTargetedRotationAngle(180 - (gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("PhysicsCharacter3D").getForwardAngle()), null);
}
}
}

}


{

gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects1);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{isConditionTrue_0 = (Math.abs(gdjs.evtTools.common.angleDifference((( gdjs.Mine3DCode.GDPlayerObjects1.length === 0 ) ? 0 :gdjs.Mine3DCode.GDPlayerObjects1[0].getBehavior("ThirdPersonCamera").TargetedRotationAngle(null)) + 90, gdjs.evtTools.camera.getCameraRotation(runtimeScene, "", 0))) > 90);
}
if (isConditionTrue_0) {
/* Reuse gdjs.Mine3DCode.GDPlayerObjects1 */
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects1[i].getBehavior("ThirdPersonCamera").SetRotationHalfwayDuration(1000000, null);
}
}
}

}


};gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDControlsToggleObjects2Objects = Hashtable.newFrom({"ControlsToggle": gdjs.Mine3DCode.GDControlsToggleObjects2});
gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDJoystickObjects3Objects = Hashtable.newFrom({"Joystick": gdjs.Mine3DCode.GDJoystickObjects3});
gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDJoystickObjects2Objects = Hashtable.newFrom({"Joystick": gdjs.Mine3DCode.GDJoystickObjects2});
gdjs.Mine3DCode.eventsList7 = function(runtimeScene) {

{

gdjs.copyArray(runtimeScene.getObjects("Joystick"), gdjs.Mine3DCode.GDJoystickObjects2);
gdjs.copyArray(runtimeScene.getObjects("JumpButton"), gdjs.Mine3DCode.GDJumpButtonObjects2);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = !(gdjs.evtsExt__SpriteMultitouchJoystick__HasTouchStartedOnScreenSide.func(runtimeScene, gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDJoystickObjects2Objects, "Left", null));
if (isConditionTrue_0) {
isConditionTrue_0 = false;
for (var i = 0, k = 0, l = gdjs.Mine3DCode.GDJumpButtonObjects2.length;i<l;++i) {
    if ( !(gdjs.Mine3DCode.GDJumpButtonObjects2[i].getBehavior("MultitouchButton").IsPressed(null)) ) {
        isConditionTrue_0 = true;
        gdjs.Mine3DCode.GDJumpButtonObjects2[k] = gdjs.Mine3DCode.GDJumpButtonObjects2[i];
        ++k;
    }
}
gdjs.Mine3DCode.GDJumpButtonObjects2.length = k;
}
if (isConditionTrue_0) {
{gdjs.evtsExt__MousePointerLock__RequestPointerLock.func(runtimeScene, null);
}
}

}


};gdjs.Mine3DCode.eventsList8 = function(runtimeScene) {

{

gdjs.copyArray(runtimeScene.getObjects("Joystick"), gdjs.Mine3DCode.GDJoystickObjects3);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtsExt__SpriteMultitouchJoystick__HasTouchStartedOnScreenSide.func(runtimeScene, gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDJoystickObjects3Objects, "Left", null);
if (isConditionTrue_0) {
/* Reuse gdjs.Mine3DCode.GDJoystickObjects3 */
{for(var i = 0, len = gdjs.Mine3DCode.GDJoystickObjects3.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJoystickObjects3[i].TeleportAndPress(null);
}
}
}

}


{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.input.isMouseButtonPressed(runtimeScene, "Left");
if (isConditionTrue_0) {
isConditionTrue_0 = false;
{isConditionTrue_0 = runtimeScene.getOnceTriggers().triggerOnce(14135380);
}
}
if (isConditionTrue_0) {

{ //Subevents
gdjs.Mine3DCode.eventsList7(runtimeScene);} //End of subevents
}

}


};gdjs.Mine3DCode.eventsList9 = function(runtimeScene) {

{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{isConditionTrue_0 = !runtimeScene.getScene().getVariables().getFromIndex(1).getAsBoolean();
}
if (isConditionTrue_0) {
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetRotationHalfwayDuration(2, null);
}
}
}

}


{


let isConditionTrue_0 = false;
{
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects2);
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetRotationHalfwayDuration(0.5, null);
}
}
}

}


{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{isConditionTrue_0 = runtimeScene.getOnceTriggers().triggerOnce(14139436);
}
if (isConditionTrue_0) {
{runtimeScene.getScene().getVariables().getFromIndex(1).setBoolean(false);
}
}

}


};gdjs.Mine3DCode.eventsList10 = function(runtimeScene) {

{

gdjs.copyArray(runtimeScene.getObjects("ControlsToggle"), gdjs.Mine3DCode.GDControlsToggleObjects2);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.input.cursorOnObject(gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDControlsToggleObjects2Objects, runtimeScene, true, true);
if (isConditionTrue_0) {

{ //Subevents
gdjs.Mine3DCode.eventsList8(runtimeScene);} //End of subevents
}

}


{

gdjs.copyArray(runtimeScene.getObjects("Joystick"), gdjs.Mine3DCode.GDJoystickObjects1);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
for (var i = 0, k = 0, l = gdjs.Mine3DCode.GDJoystickObjects1.length;i<l;++i) {
    if ( gdjs.Mine3DCode.GDJoystickObjects1[i].IsPressed(null) ) {
        isConditionTrue_0 = true;
        gdjs.Mine3DCode.GDJoystickObjects1[k] = gdjs.Mine3DCode.GDJoystickObjects1[i];
        ++k;
    }
}
gdjs.Mine3DCode.GDJoystickObjects1.length = k;
if (isConditionTrue_0) {

{ //Subevents
gdjs.Mine3DCode.eventsList9(runtimeScene);} //End of subevents
}

}


};gdjs.Mine3DCode.eventsList11 = function(runtimeScene) {

{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.runtimeScene.sceneJustBegins(runtimeScene);
if (isConditionTrue_0) {
gdjs.copyArray(runtimeScene.getObjects("Joystick"), gdjs.Mine3DCode.GDJoystickObjects2);
gdjs.copyArray(runtimeScene.getObjects("JumpButton"), gdjs.Mine3DCode.GDJumpButtonObjects2);
{for(var i = 0, len = gdjs.Mine3DCode.GDJoystickObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJoystickObjects2[i].hide();
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDJumpButtonObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJumpButtonObjects2[i].hide();
}
}
{for(var i = 0, len = gdjs.Mine3DCode.GDJoystickObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDJoystickObjects2[i].ActivateControl(false, null);
}
}
}

}


{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{isConditionTrue_0 = (runtimeScene.getScene().getVariables().getFromIndex(0).getAsString() == "Touch");
}
if (isConditionTrue_0) {

{ //Subevents
gdjs.Mine3DCode.eventsList10(runtimeScene);} //End of subevents
}

}


};gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDControlsToggleObjects2Objects = Hashtable.newFrom({"ControlsToggle": gdjs.Mine3DCode.GDControlsToggleObjects2});
gdjs.Mine3DCode.eventsList12 = function(runtimeScene) {

{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{isConditionTrue_0 = !runtimeScene.getScene().getVariables().getFromIndex(1).getAsBoolean();
}
if (isConditionTrue_0) {
gdjs.copyArray(gdjs.Mine3DCode.GDPlayerObjects1, gdjs.Mine3DCode.GDPlayerObjects2);

{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetRotationHalfwayDuration(2, null);
}
}
}

}


{


let isConditionTrue_0 = false;
{
gdjs.copyArray(gdjs.Mine3DCode.GDPlayerObjects1, gdjs.Mine3DCode.GDPlayerObjects2);

{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects2.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects2[i].getBehavior("ThirdPersonCamera").SetRotationHalfwayDuration(1000000, null);
}
}
}

}


{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{isConditionTrue_0 = runtimeScene.getOnceTriggers().triggerOnce(14144988);
}
if (isConditionTrue_0) {
{runtimeScene.getScene().getVariables().getFromIndex(1).setBoolean(false);
}
}

}


};gdjs.Mine3DCode.eventsList13 = function(runtimeScene) {

{

gdjs.copyArray(runtimeScene.getObjects("ControlsToggle"), gdjs.Mine3DCode.GDControlsToggleObjects2);

let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.input.isMouseButtonPressed(runtimeScene, "Left");
if (isConditionTrue_0) {
isConditionTrue_0 = false;
isConditionTrue_0 = !(gdjs.evtsExt__MousePointerLock__isPointerLocked.func(runtimeScene, null));
if (isConditionTrue_0) {
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.input.cursorOnObject(gdjs.Mine3DCode.mapOfGDgdjs_9546Mine3DCode_9546GDControlsToggleObjects2Objects, runtimeScene, true, true);
}
}
if (isConditionTrue_0) {
{gdjs.evtsExt__MousePointerLock__RequestPointerLock.func(runtimeScene, null);
}
}

}


{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
isConditionTrue_0 = gdjs.evtTools.input.anyKeyPressed(runtimeScene);
if (isConditionTrue_0) {
gdjs.copyArray(runtimeScene.getObjects("Player"), gdjs.Mine3DCode.GDPlayerObjects1);
{for(var i = 0, len = gdjs.Mine3DCode.GDPlayerObjects1.length ;i < len;++i) {
    gdjs.Mine3DCode.GDPlayerObjects1[i].getBehavior("ThirdPersonCamera").SetRotationHalfwayDuration(2, null);
}
}

{ //Subevents
gdjs.Mine3DCode.eventsList12(runtimeScene);} //End of subevents
}

}


};gdjs.Mine3DCode.eventsList14 = function(runtimeScene) {

{


let isConditionTrue_0 = false;
isConditionTrue_0 = false;
{isConditionTrue_0 = (runtimeScene.getScene().getVariables().getFromIndex(0).getAsString() == "Keyboard");
}
if (isConditionTrue_0) {

{ //Subevents
gdjs.Mine3DCode.eventsList13(runtimeScene);} //End of subevents
}

}


};gdjs.Mine3DCode.eventsList15 = function(runtimeScene) {

{


gdjs.Mine3DCode.eventsList0(runtimeScene);
}


{


gdjs.Mine3DCode.eventsList2(runtimeScene);
}


{


gdjs.Mine3DCode.eventsList3(runtimeScene);
}


{


gdjs.Mine3DCode.eventsList5(runtimeScene);
}


{


gdjs.Mine3DCode.eventsList6(runtimeScene);
}


{


gdjs.Mine3DCode.eventsList11(runtimeScene);
}


{


gdjs.Mine3DCode.eventsList14(runtimeScene);
}


};

gdjs.Mine3DCode.func = function(runtimeScene) {
runtimeScene.getOnceTriggers().startNewFrame();

gdjs.Mine3DCode.GDGroundObjects1.length = 0;
gdjs.Mine3DCode.GDGroundObjects2.length = 0;
gdjs.Mine3DCode.GDGroundObjects3.length = 0;
gdjs.Mine3DCode.GDGroundObjects4.length = 0;
gdjs.Mine3DCode.GDPlayerObjects1.length = 0;
gdjs.Mine3DCode.GDPlayerObjects2.length = 0;
gdjs.Mine3DCode.GDPlayerObjects3.length = 0;
gdjs.Mine3DCode.GDPlayerObjects4.length = 0;
gdjs.Mine3DCode.GDObstacleObjects1.length = 0;
gdjs.Mine3DCode.GDObstacleObjects2.length = 0;
gdjs.Mine3DCode.GDObstacleObjects3.length = 0;
gdjs.Mine3DCode.GDObstacleObjects4.length = 0;
gdjs.Mine3DCode.GDCoinObjects1.length = 0;
gdjs.Mine3DCode.GDCoinObjects2.length = 0;
gdjs.Mine3DCode.GDCoinObjects3.length = 0;
gdjs.Mine3DCode.GDCoinObjects4.length = 0;
gdjs.Mine3DCode.GDPushableBoxObjects1.length = 0;
gdjs.Mine3DCode.GDPushableBoxObjects2.length = 0;
gdjs.Mine3DCode.GDPushableBoxObjects3.length = 0;
gdjs.Mine3DCode.GDPushableBoxObjects4.length = 0;
gdjs.Mine3DCode.GDJoystickObjects1.length = 0;
gdjs.Mine3DCode.GDJoystickObjects2.length = 0;
gdjs.Mine3DCode.GDJoystickObjects3.length = 0;
gdjs.Mine3DCode.GDJoystickObjects4.length = 0;
gdjs.Mine3DCode.GDJumpButtonObjects1.length = 0;
gdjs.Mine3DCode.GDJumpButtonObjects2.length = 0;
gdjs.Mine3DCode.GDJumpButtonObjects3.length = 0;
gdjs.Mine3DCode.GDJumpButtonObjects4.length = 0;
gdjs.Mine3DCode.GDControlsToggleObjects1.length = 0;
gdjs.Mine3DCode.GDControlsToggleObjects2.length = 0;
gdjs.Mine3DCode.GDControlsToggleObjects3.length = 0;
gdjs.Mine3DCode.GDControlsToggleObjects4.length = 0;
gdjs.Mine3DCode.GDMineBlockObjects1.length = 0;
gdjs.Mine3DCode.GDMineBlockObjects2.length = 0;
gdjs.Mine3DCode.GDMineBlockObjects3.length = 0;
gdjs.Mine3DCode.GDMineBlockObjects4.length = 0;
gdjs.Mine3DCode.GDPickaxeButtonObjects1.length = 0;
gdjs.Mine3DCode.GDPickaxeButtonObjects2.length = 0;
gdjs.Mine3DCode.GDPickaxeButtonObjects3.length = 0;
gdjs.Mine3DCode.GDPickaxeButtonObjects4.length = 0;
gdjs.Mine3DCode.GDOreHUDObjects1.length = 0;
gdjs.Mine3DCode.GDOreHUDObjects2.length = 0;
gdjs.Mine3DCode.GDOreHUDObjects3.length = 0;
gdjs.Mine3DCode.GDOreHUDObjects4.length = 0;
gdjs.Mine3DCode.GDPickaxeLabelObjects1.length = 0;
gdjs.Mine3DCode.GDPickaxeLabelObjects2.length = 0;
gdjs.Mine3DCode.GDPickaxeLabelObjects3.length = 0;
gdjs.Mine3DCode.GDPickaxeLabelObjects4.length = 0;
gdjs.Mine3DCode.GDMineHintObjects1.length = 0;
gdjs.Mine3DCode.GDMineHintObjects2.length = 0;
gdjs.Mine3DCode.GDMineHintObjects3.length = 0;
gdjs.Mine3DCode.GDMineHintObjects4.length = 0;

gdjs.Mine3DCode.eventsList15(runtimeScene);
gdjs.Mine3DCode.GDGroundObjects1.length = 0;
gdjs.Mine3DCode.GDGroundObjects2.length = 0;
gdjs.Mine3DCode.GDGroundObjects3.length = 0;
gdjs.Mine3DCode.GDGroundObjects4.length = 0;
gdjs.Mine3DCode.GDPlayerObjects1.length = 0;
gdjs.Mine3DCode.GDPlayerObjects2.length = 0;
gdjs.Mine3DCode.GDPlayerObjects3.length = 0;
gdjs.Mine3DCode.GDPlayerObjects4.length = 0;
gdjs.Mine3DCode.GDObstacleObjects1.length = 0;
gdjs.Mine3DCode.GDObstacleObjects2.length = 0;
gdjs.Mine3DCode.GDObstacleObjects3.length = 0;
gdjs.Mine3DCode.GDObstacleObjects4.length = 0;
gdjs.Mine3DCode.GDCoinObjects1.length = 0;
gdjs.Mine3DCode.GDCoinObjects2.length = 0;
gdjs.Mine3DCode.GDCoinObjects3.length = 0;
gdjs.Mine3DCode.GDCoinObjects4.length = 0;
gdjs.Mine3DCode.GDPushableBoxObjects1.length = 0;
gdjs.Mine3DCode.GDPushableBoxObjects2.length = 0;
gdjs.Mine3DCode.GDPushableBoxObjects3.length = 0;
gdjs.Mine3DCode.GDPushableBoxObjects4.length = 0;
gdjs.Mine3DCode.GDJoystickObjects1.length = 0;
gdjs.Mine3DCode.GDJoystickObjects2.length = 0;
gdjs.Mine3DCode.GDJoystickObjects3.length = 0;
gdjs.Mine3DCode.GDJoystickObjects4.length = 0;
gdjs.Mine3DCode.GDJumpButtonObjects1.length = 0;
gdjs.Mine3DCode.GDJumpButtonObjects2.length = 0;
gdjs.Mine3DCode.GDJumpButtonObjects3.length = 0;
gdjs.Mine3DCode.GDJumpButtonObjects4.length = 0;
gdjs.Mine3DCode.GDControlsToggleObjects1.length = 0;
gdjs.Mine3DCode.GDControlsToggleObjects2.length = 0;
gdjs.Mine3DCode.GDControlsToggleObjects3.length = 0;
gdjs.Mine3DCode.GDControlsToggleObjects4.length = 0;
gdjs.Mine3DCode.GDMineBlockObjects1.length = 0;
gdjs.Mine3DCode.GDMineBlockObjects2.length = 0;
gdjs.Mine3DCode.GDMineBlockObjects3.length = 0;
gdjs.Mine3DCode.GDMineBlockObjects4.length = 0;
gdjs.Mine3DCode.GDPickaxeButtonObjects1.length = 0;
gdjs.Mine3DCode.GDPickaxeButtonObjects2.length = 0;
gdjs.Mine3DCode.GDPickaxeButtonObjects3.length = 0;
gdjs.Mine3DCode.GDPickaxeButtonObjects4.length = 0;
gdjs.Mine3DCode.GDOreHUDObjects1.length = 0;
gdjs.Mine3DCode.GDOreHUDObjects2.length = 0;
gdjs.Mine3DCode.GDOreHUDObjects3.length = 0;
gdjs.Mine3DCode.GDOreHUDObjects4.length = 0;
gdjs.Mine3DCode.GDPickaxeLabelObjects1.length = 0;
gdjs.Mine3DCode.GDPickaxeLabelObjects2.length = 0;
gdjs.Mine3DCode.GDPickaxeLabelObjects3.length = 0;
gdjs.Mine3DCode.GDPickaxeLabelObjects4.length = 0;
gdjs.Mine3DCode.GDMineHintObjects1.length = 0;
gdjs.Mine3DCode.GDMineHintObjects2.length = 0;
gdjs.Mine3DCode.GDMineHintObjects3.length = 0;
gdjs.Mine3DCode.GDMineHintObjects4.length = 0;


return;

}

gdjs['Mine3DCode'] = gdjs.Mine3DCode;
