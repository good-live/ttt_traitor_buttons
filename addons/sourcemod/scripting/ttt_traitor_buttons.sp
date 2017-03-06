#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <ttt>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Traitor Buttons",
	author = PLUGIN_AUTHOR,
	description = "Only Traitor can push Traitor buttons",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

ArrayList g_aButtonNames;
ArrayList g_aButtons;

public void OnPluginStart()
{
	g_aButtons = new ArrayList();
	g_aButtonNames = new ArrayList(64);
	
	LoadCFG();
	LoadButtons();
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	
	RegAdminCmd("sm_reloadbuttons", Command_Reload, ADMFLAG_ROOT);
}

public Action Command_Reload(int client, int args){
	ReplyToCommand(client, "Reloading buttons");
	LoadButtons();
	return Plugin_Handled;
}

void LoadButtons(){
	g_aButtons.Clear();
	char buffer[64];
	int ent = -1;
	//Search for buttons
	while ((ent = FindEntityByClassname(ent, "func_button")) != -1) 
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(g_aButtonNames.FindString(buffer) != -1)
		{
			SetEntProp(ent, Prop_Data, "m_bLocked", 1, 1);
			g_aButtons.Push(ent);
		}
	}
	
	ent = -1;
	
	//Search for doors
	while ((ent = FindEntityByClassname(ent, "func_door")) != -1) 
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(g_aButtonNames.FindString(buffer) != -1)
		{
			SetEntProp(ent, Prop_Data, "m_bLocked", 1, 1);
			g_aButtons.Push(ent);
		}
	}
	
	//Search for func_door_rotating
	while ((ent = FindEntityByClassname(ent, "func_door_rotating")) != -1) 
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(g_aButtonNames.FindString(buffer) != -1)
		{
			SetEntProp(ent, Prop_Data, "m_bLocked", 1, 1);
			g_aButtons.Push(ent);
		}
	}
	
	ent = -1;
	//Search for prop_door_rotating
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating")) != -1) 
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(g_aButtonNames.FindString(buffer) != -1)
		{
			SetEntProp(ent, Prop_Data, "m_bLocked", 1, 1);
			g_aButtons.Push(ent);
		}
	}
}

public void OnMapStart()
{
	LoadButtons();
}

public void LoadCFG()
{
	char sBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/buttons.cfg");
	
	KeyValues kv = new KeyValues("Buttons");

	if(!kv.ImportFromFile(sBuffer))
		SetFailState("Couldn't read file %s! Will be built now!", sBuffer);
	
	kv.Rewind();
	
	if (!kv.GotoFirstSubKey())
		return;
	
	char buffer[64];
	do
	{
		if(kv.GetSectionName(buffer, sizeof(buffer)))
			if(kv.GetNum("enabled"))
				g_aButtonNames.PushString(buffer);
	} while (kv.GotoNextKey());
	
	delete kv;
}

public void ButtonPressed(const char[] output, int caller, int activator, float delay)
{
	OnButtonPressed(activator, caller);
}

public void OnButtonPressed(int activator, int caller) 
{
	if(TTT_GetClientRole(activator) == TTT_TEAM_TRAITOR)
	{
		if(g_aButtons.FindValue(caller) !=  -1)
		{
			SetEntProp(caller, Prop_Data, "m_bLocked", 0, 1);
			CreateTimer(1.0, Timer_Button, caller);
		}
	}
}

public Action Timer_Button(Handle timer, int entity)
{
	SetEntProp(entity, Prop_Data, "m_bLocked", 1, 1);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) 
{ 
    for (int i = 0; i < g_aButtons.Length; i++)
    	SetEntProp(g_aButtons.Get(i), Prop_Data, "m_bLocked", 1, 1);
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon, int &tickcount) {
	static int iPlayerPrevButtons[MAXPLAYERS + 1];
	if (!(iPlayerPrevButtons[client] & IN_USE) && iButtons & IN_USE) {
		if (IsClientInGame(client) && IsPlayerAlive(client)) {
			int ent = GetClientAimTarget(client, false);
			if (!IsValidEntity(ent)) {
				iPlayerPrevButtons[client] = iButtons;
				return;
			}
			if (HasEntProp(ent, Prop_Data, "m_iName")) {
				char itemName[128];
				//GetEntPropString(ent, Prop_Data, "m_iName", itemName, sizeof(itemName));
				GetEntityClassname(ent, itemName, sizeof(itemName));
				if (StrContains(itemName, "door", false) != -1 || StrContains(itemName, "button", false) != -1) {
					OnButtonPressed(client, ent);
				}
			}
		}
	}
	iPlayerPrevButtons[client] = iButtons;
}
