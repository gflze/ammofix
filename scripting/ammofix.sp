#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
#pragma newdecls required
 
#define VERSION "1.1"
 
public Plugin myinfo = 
{
	name = "Ammo Fixerino",
	author = "an autismo hydrologist",
	description = "Fixes a dumb CS:GO bug",
	version = VERSION,
	url = "isuck.com"
}
 
Handle g_hSDK_StockPlayerAmmo;
bool bLateLoad;
 
public void OnPluginStart() {
	GameData hGameConf = LoadGameConfigFile("ammofix.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("No gamedata found for ammofix. RIP.");
 
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "StockPlayerAmmo");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDK_StockPlayerAmmo = EndPrepSDKCall();
 
	CloseHandle(hGameConf);
 
	if(g_hSDK_StockPlayerAmmo == INVALID_HANDLE) {
		SetFailState("Unable to prepare virtual function CCSPlayer::StockPlayerAmmo");
		return;
	}
 
	if (bLateLoad) {
		int i = INVALID_ENT_REFERENCE;
		while((i = FindEntityByClassname(i, "game_player_equip")) != INVALID_ENT_REFERENCE) {
			SDKHook(i, SDKHook_Use, OnEquipUse);
		}
	}
}
 
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	return APLRes_Success;
}
 
public void OnEntityCreated(int entity, const char[] classname) {
	if(StrEqual(classname, "game_player_equip")) {
		SDKHook(entity, SDKHook_Use, OnEquipUse);
	}
}
 
public Action OnEquipUse(int entity, int other) {
	static int maxEntries = -1;
 
	if(maxEntries == -1) {
		maxEntries = GetEntPropArraySize(entity, Prop_Data, "m_weaponNames");
	}
 
	bool hasAmmo = false;
 
	if(0 >= other || other > MaxClients) {
		return Plugin_Continue;
	}
 
	for(int i = 0; i < maxEntries; i++) {
		char sWeapon[32];
 
		GetEntPropString(entity, Prop_Data, "m_weaponNames", sWeapon, sizeof(sWeapon), i);
 
		if(!sWeapon[0]) {
			continue;
		}
 
		if(StrContains(sWeapon, "ammo_", false) != -1) {
			if(!hasAmmo) {
				int weapon = GetEntPropEnt(other, Prop_Data, "m_hActiveWeapon", 0);
 
				if(weapon != INVALID_ENT_REFERENCE) {
					SDKCall(g_hSDK_StockPlayerAmmo, other, weapon);
				}
 
				hasAmmo = true;
			}
		}
	}
 
	return Plugin_Continue;
}