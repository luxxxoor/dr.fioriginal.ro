#include <amxmodx>
#include <fakemeta>
#include <fakemeta_stocks>
#include <cstrike>

#define PLUGIN	"Tetris ASCII newmenus.inc"
#define AUTHOR	"Albernaz o Carniceiro Demoniaco"
#define VERSION	"1.2"

new const DICTIONARY[] = "tetris.txt";

enum ML_DEFINITION
{
	TETRIS_TITLE,
	TETRIS_GAME_OVER,
	TETRIS_PLAY_AGAIN,
	TETRIS_EXIT,
	TETRIS_MUSIC_ON,
	TETRIS_MUSIC_OFF,
	TETRIS_DIFFICULTY_LEVEL,
	TETRIS_START_GAME,
	TETRIS_DIFFICULTY
}

const TETRIS_TITLE_LEN = 20
const TETRIS_GAME_OVER_LEN = 15
const TETRIS_PLAY_AGAIN_LEN = 20
const TETRIS_EXIT_LEN = 15
const TETRIS_MUSIC_LEN = 20
const TETRIS_DIFFICULTY_LEVEL_LEN = 20
const TETRIS_START_GAME_LEN = 15
const TETRIS_DIFFICULTY_LEN = 15

new ML_DefinitionsString[ML_DEFINITION][] = {"TETRIS_TITLE","TETRIS_GAME_OVER","TETRIS_PLAY_AGAIN","TETRIS_EXIT","TETRIS_MUSIC_ON","TETRIS_MUSIC_OFF","TETRIS_DIFFICULTY_LEVEL","TETRIS_START_GAME","TETRIS_DIFFICULTY"}

enum GAME_STATE
{
	START,
	IN_GAME,
	GAME_OVER
}

enum POSITION
{
	ROW,
	COL
}

enum PIECE_NAME
{
	I,
	J,
	L,
	O,
	S,
	T,
	Z
}

enum TABLE_DIM
{
	ROWS,
	COLS
}

enum CELL_COLOR
{
	INACTIVE,
	ACTIVE
}

enum SOUND
{
	SELECTION,
	LINE,
	FALL,
	GAMEOVER
}

new Sounds[SOUND][] = { "tetris/selection.wav", "tetris/line.wav" , "tetris/fall.wav", "tetris/gameover.wav"}

enum MUSIC
{
	MUSIC1,
	MUSIC2,
	MUSIC3
}

new Musics[MUSIC][] = { "tetris/music1.mp3","tetris/music2.mp3","tetris/music3.mp3"}

enum DIFFICULTY_LEVEL
{
	EASY,
	NORMAL,
	HARD
}

enum CVAR
{
	AMBIENT_SOUND
}
new Cvars[CVAR]

new Float:difficultyLevelsTaskDelay[DIFFICULTY_LEVEL] = {_:0.3,_:0.25,_:0.2}
new DIFFICULTY_LEVEL:playersDifficultyLevel[MAX_PLAYERS+1];

new cellChar[] = {"O"}
new cellCharColors[CELL_COLOR][] = {"\d","\r"}

const PieceSquareMaxWidth = 4;
new const PiecesSquareWidth[PIECE_NAME] = {4,3,3,2,3,3,3}
new Array:PiecesData[PIECE_NAME]

const TableRows = 14
const TableCols = 10
new Array:PlayersTables[MAX_PLAYERS+1]

new GAME_STATE:PlayersGameState[MAX_PLAYERS+1]

new GameStatesMenusIDs[GAME_STATE]

new Array:PlayersCurrentPieceData[MAX_PLAYERS+1]
new PIECE_NAME:PlayersCurrentPieceName[MAX_PLAYERS+1]
new PlayersCurrentPiecePosition[MAX_PLAYERS+1][POSITION]

new Array:PlayersNextPieceData[MAX_PLAYERS+1]
new PIECE_NAME:PlayersNextPieceName[MAX_PLAYERS+1]
new PlayersNextPiecePosition[MAX_PLAYERS+1][POSITION]

new bool:PlayersTableCellActive[MAX_PLAYERS+1]

new PlayersTaskID[MAX_PLAYERS+1]
new Float:PlayersTaskDelay[MAX_PLAYERS+1]
new PlayersMenuInGame[MAX_PLAYERS+1]

new PlayersButtons = IN_MOVELEFT | IN_MOVERIGHT | IN_FORWARD | IN_BACK;

new PlayersPreviousPressedButton[MAX_PLAYERS+1];
new PlayersIsPlaying[MAX_PLAYERS+1];

new Float:PlayersPreviousMaxspeed[MAX_PLAYERS+1]

new ForwardPlayerPostThink;

new playersPlaying

new bool:playersMusic[MAX_PLAYERS+1]

public plugin_precache()
{
	for(new SOUND:i=SOUND:0;i<SOUND;i++)
		precache_sound(Sounds[i])
	
	for(new MUSIC:i=MUSIC:0;i<MUSIC;i++)
		precache_sound(Musics[i])
}

playSound(id,sound[])
{
	if(get_pcvar_num(Cvars[AMBIENT_SOUND]))
	{
		new Float:origin[3]
		pev(id,pev_origin,origin)
		
		EF_EmitAmbientSound(0,origin,sound,1.0,ATTN_NORM,0,PITCH_NORM);
	}
	else
	{
		client_cmd(id,"spk %s",sound);
	}
}

public plugin_cfg()
{
	Cvars[AMBIENT_SOUND] = register_cvar("tetris_ambient_sound", "0");
	
	for(new PIECE_NAME:i=I;i<PIECE_NAME;i++)
	{
		new pieceSquareWidth = PiecesSquareWidth[i];
		PiecesData[i] =  createBiArray(pieceSquareWidth,pieceSquareWidth);
	}
	
	setBiArrayCell(Array:PiecesData[I],0,1,true) //	O
	setBiArrayCell(Array:PiecesData[I],1,1,true) //	O
	setBiArrayCell(Array:PiecesData[I],2,1,true) //	O
	setBiArrayCell(Array:PiecesData[I],3,1,true) //	O
	
	setBiArrayCell(Array:PiecesData[J],0,0,true) //	O
	setBiArrayCell(Array:PiecesData[J],1,0,true) //	OOO
	setBiArrayCell(Array:PiecesData[J],1,1,true)
	setBiArrayCell(Array:PiecesData[J],1,2,true)
	
	setBiArrayCell(Array:PiecesData[J],0,0,true) //	O
	setBiArrayCell(Array:PiecesData[J],1,0,true) //	OOO
	setBiArrayCell(Array:PiecesData[J],1,1,true)
	setBiArrayCell(Array:PiecesData[J],1,2,true)
	
	setBiArrayCell(Array:PiecesData[L],0,2,true) //	  O
	setBiArrayCell(Array:PiecesData[L],1,0,true) //	OOO
	setBiArrayCell(Array:PiecesData[L],1,1,true)
	setBiArrayCell(Array:PiecesData[L],1,2,true)
	
	setBiArrayCell(Array:PiecesData[O],0,0,true) //	OO
	setBiArrayCell(Array:PiecesData[O],0,1,true) //	OO
	setBiArrayCell(Array:PiecesData[O],1,0,true)
	setBiArrayCell(Array:PiecesData[O],1,1,true)
	
	setBiArrayCell(Array:PiecesData[S],0,1,true) //	 OO
	setBiArrayCell(Array:PiecesData[S],0,2,true) //	OO
	setBiArrayCell(Array:PiecesData[S],1,0,true)
	setBiArrayCell(Array:PiecesData[S],1,1,true)
	
	setBiArrayCell(Array:PiecesData[T],0,1,true) //	 O
	setBiArrayCell(Array:PiecesData[T],1,0,true) //	OOO
	setBiArrayCell(Array:PiecesData[T],1,1,true)
	setBiArrayCell(Array:PiecesData[T],1,2,true)
	
	setBiArrayCell(Array:PiecesData[Z],0,0,true) //	OO
	setBiArrayCell(Array:PiecesData[Z],0,1,true) //	 OO
	setBiArrayCell(Array:PiecesData[Z],1,1,true)
	setBiArrayCell(Array:PiecesData[Z],1,2,true)
	
	GameStatesMenusIDs[START] 		= funcidx("menuTetrisStart");
	GameStatesMenusIDs[IN_GAME] 	= funcidx("menuTetrisInGamePre");
	GameStatesMenusIDs[GAME_OVER] 	= funcidx("menuTetrisGameOver");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say !tetris","menuTetrisChecker");
	register_cvar("tetrisASCIIVersion",VERSION,FCVAR_SERVER);
	register_dictionary(DICTIONARY);
}

public playerPostThink(id)
{
	if(PlayersIsPlaying[id])
	{
		new Float:maxspeed 
		
		pev(id,pev_maxspeed,maxspeed);
			
		if((maxspeed != 1.0) && (maxspeed != PlayersPreviousMaxspeed[id]))
		{
			PlayersPreviousMaxspeed[id] = maxspeed;
		}
		
		set_pev(id,pev_maxspeed,1.0)
		
		new button = pev(id, pev_button)
		
		new myButton = button & PlayersButtons;
		
		if(myButton)
		{	
			new buttonUnique = myButton & ~PlayersPreviousPressedButton[id]

			if(buttonUnique)
			{
				new piecePosition[POSITION]
				new PIECE_NAME:pieceName = PlayersCurrentPieceName[id]
				
				new pieceSquareWidth = PiecesSquareWidth[pieceName]
				new Array:pieceData = createBiArray(pieceSquareWidth,pieceSquareWidth)
				
				clonePiece(PlayersCurrentPieceData[id],pieceData,PlayersCurrentPiecePosition[id],piecePosition,pieceName);
				
				switch(buttonUnique)
				{
					case IN_MOVELEFT:
					{
						piecePosition[COL]--;
					}
					case IN_MOVERIGHT:
					{
						piecePosition[COL]++;
					}
					case IN_FORWARD:
					{
						rotatePiece(pieceData,pieceName)
					}
					case IN_BACK:
					{
						piecePosition[ROW]++;	
					}
				}
				
				if(isValidPieceInTable(id,pieceData,piecePosition,pieceName))
				{
					PlayersCurrentPiecePosition[id] = piecePosition;
					PlayersCurrentPieceData[id] = pieceData;
				}
				
				menuTetrisInGame(id)
			}
		}
		
		PlayersPreviousPressedButton[id] = button;
	}
}

public client_connect(id)
{
	PlayersGameState[id] = START
	playersDifficultyLevel[id] = DIFFICULTY_LEVEL:0;
	playersMusic[id] = true
}

public client_disconnected(id)
{
	if(PlayersIsPlaying[id])
		playerQuitingGame(id);
}

newTask(id,&taskID,&Float:taskDelay)
{
	taskDelay = difficultyLevelsTaskDelay[playersDifficultyLevel[id]]
	
	do
	{
		taskID = random(999999);
	}
	while(task_exists(taskID));
}

Array:createBiArray(rows,cols)
{
	new Array:array = ArrayCreate(rows)
	
	for(new i=0;i<rows;i++)
	{
		new Array:line = ArrayCreate(cols)
		
		for(new i=0;i<cols;i++)
			ArrayPushCell(line,false)
		
		ArrayPushCell(array,line)
	}
	
	return array;	
}
destroyBiArray(Array:array,rows)
{
	if(array)
	{
		for(new i=0;i<rows;i++)
		{
			new Array:line = ArrayGetCell(array,i)
			ArrayDestroy(line)
		}
		
		ArrayDestroy(array)
	}
}

rotatePiece(&Array:pieceData,PIECE_NAME:pieceName)
{
	new pieceSquareWidth = PiecesSquareWidth[pieceName]
	new biggerIndex = pieceSquareWidth - 1;
	
	new Array:newPieceData = createBiArray(pieceSquareWidth,pieceSquareWidth)
	
	for(new i=0;i<pieceSquareWidth;i++)
		for(new j=0;j<pieceSquareWidth;j++)
			setBiArrayCell(newPieceData,i,j,getBiArrayCell(pieceData,biggerIndex - j,i))
		
	destroyBiArray(pieceData,pieceSquareWidth);
			
	pieceData = newPieceData;
}

clonePiece(Array:piece1Data,Array:piece2Data,piece1Position[POSITION],piece2Position[POSITION],PIECE_NAME:pieceName)
{
	new pieceSquareWidth = PiecesSquareWidth[pieceName]
	
	for(new i = 0 ; i< pieceSquareWidth ; i++)
		for(new j = 0 ; j< pieceSquareWidth ; j++)
			setBiArrayCell(piece2Data,i,j,getBiArrayCell(piece1Data,i,j))
		
	for(new POSITION:pos = ROW; pos < POSITION;pos++)
		piece2Position[pos] = piece1Position[pos];
}

getRandomPiece(&Array:pieceData,piecePosition[POSITION],&PIECE_NAME:pieceName)
{
	pieceName = PIECE_NAME:random(_:PIECE_NAME);
	new pieceSquareWidth = PiecesSquareWidth[pieceName]
	
	pieceData = createBiArray(pieceSquareWidth,pieceSquareWidth)
	
	clonePiece(PiecesData[pieceName],pieceData,piecePosition,piecePosition,pieceName);
	
	initPiecePosition(piecePosition,pieceName);
}

initPiecePosition(piecePosition[POSITION],PIECE_NAME:pieceName)
{
	new pieceSquareWidth = PiecesSquareWidth[pieceName];
	
	piecePosition[ROW] = -1
	piecePosition[COL] = (TableCols / 2 + TableCols % 2) - (pieceSquareWidth / 2)
}

initTable(id)
{
	PlayersTables[id] = createBiArray(TableRows,TableCols)
}

initPlayerGame(id)
{
	PlayersGameState[id] = IN_GAME;
	
	initTable(id)

	getRandomPiece(PlayersCurrentPieceData[id],PlayersCurrentPiecePosition[id],PlayersCurrentPieceName[id])
	getRandomPiece(PlayersNextPieceData[id],PlayersNextPiecePosition[id],PlayersNextPieceName[id])
	
	new params[1]
	params[0] = id
	
	playerEnteringGame(id,true);
	
	newTask(id,PlayersTaskID[id],PlayersTaskDelay[id])
}

playerEnteringGame(id,bool:starting = false)
{
	pev(id,pev_maxspeed,PlayersPreviousMaxspeed[id])
	
	new Float:delay = PlayersTaskDelay[id]
	
	if(!starting)
		delay /= 2.0
	
	new params[1]
	params[0] = id; 
	set_task(delay,"movePieceDownTask",PlayersTaskID[id],params,1,"a",1) 
	
	if(playersMusic[id])
		client_cmd(id,"mp3 loop sound/%s",Musics[MUSIC:random(_:MUSIC)] );
	
	PlayersIsPlaying[id] = true;
	
	if(!playersPlaying++)
		ForwardPlayerPostThink = register_forward(FM_PlayerPostThink,"playerPostThink");		
}
playerQuitingGame(id)
{	
	PlayersIsPlaying[id] = false;
	
	new taskID = PlayersTaskID[id]
	
	if(task_exists(taskID))
		remove_task(taskID);
	
	set_pev(id,pev_maxspeed,PlayersPreviousMaxspeed[id])
	
	client_cmd(id,"mp3 stop")
	
	if(!--playersPlaying)
		unregister_forward(FM_PlayerPostThink,ForwardPlayerPostThink);
}

bool:getBiArrayCell(Array:table,row,col)
{
	return bool:ArrayGetCell(Array:ArrayGetCell(table,row),col)
}
setBiArrayCell(Array:table,row,col,value)
{
	ArraySetCell(Array:ArrayGetCell(table,row),col,value)
}

public menuTetrisChecker(id)
{
	if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT )
	{
		client_print_color(id, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Nu te poți juca decât cand ești mort sau dacă ești terorist!");
		return PLUGIN_HANDLED;
	}
	menuTetris(id);
	return PLUGIN_CONTINUE;
}

public menuTetris(id)
{
	callfunc_begin_i(GameStatesMenusIDs[PlayersGameState[id]])
	callfunc_push_int(id);
	callfunc_end();	
}

public menuTetrisStart(id)
{
	new menu = menu_create("","handleMenuTetrisStart");
	
	new TetrisTitle[TETRIS_TITLE_LEN+1]
	formatex(TetrisTitle,TETRIS_TITLE_LEN,"%L",LANG_PLAYER,ML_DefinitionsString[TETRIS_TITLE])
	
	new TetrisExit[TETRIS_EXIT_LEN+1]
	formatex(TetrisExit,TETRIS_EXIT_LEN,"%L",LANG_PLAYER,ML_DefinitionsString[TETRIS_EXIT])
	
	new TetrisStartGame[TETRIS_START_GAME_LEN+1]
	formatex(TetrisStartGame,TETRIS_START_GAME_LEN,"%L",LANG_PLAYER,ML_DefinitionsString[TETRIS_START_GAME])
	
	menu_setprop(menu,MPROP_TITLE,TetrisTitle);	
	menu_setprop(menu,MPROP_EXITNAME,TetrisExit);
	
	menu_additem(menu,TetrisStartGame,"1");
	
	const ML_DifficultyLevelLen = 23 + 1
	new ML_DifficultyLevel[ML_DifficultyLevelLen + 1]
	
	formatex(ML_DifficultyLevel,ML_DifficultyLevelLen,"%s%d",ML_DefinitionsString[TETRIS_DIFFICULTY_LEVEL],_:playersDifficultyLevel[id])
	
	new difficultyLevelFormat[] = "%L: ^"\r%L\w^"";
	
	const difficultyLevelLen = sizeof difficultyLevelFormat + TETRIS_DIFFICULTY_LEN + TETRIS_DIFFICULTY_LEVEL_LEN;
	new difficultyLevel[difficultyLevelLen + 1]
	
	formatex(difficultyLevel,difficultyLevelLen,difficultyLevelFormat,LANG_PLAYER,ML_DefinitionsString[TETRIS_DIFFICULTY],LANG_PLAYER,ML_DifficultyLevel)
	
	menu_additem(menu,difficultyLevel,"2");
	
	menu_display(id,menu,0);
}

public handleMenuTetrisStart(id,menu,item)
{
	if(item >= 0) 
	{
		new access, callback; 
		
		new actionString[2];		
		menu_item_getinfo(menu,item,access, actionString,1,_,_, callback);		
		new action = str_to_num(actionString);	
		
		switch(action)
		{
			case 1:
			{
				initPlayerGame(id)				
				menuTetrisInGame(id);
			}
			case 2:
			{
				if(++playersDifficultyLevel[id] == DIFFICULTY_LEVEL)
					playersDifficultyLevel[id] = DIFFICULTY_LEVEL:0
			
				playSound(id,Sounds[SELECTION]);
			
				menuTetrisStart(id);
			}
		}
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}	

canMovePieceDown(id)
{	
	new piecePosition[POSITION]
	new PIECE_NAME:pieceName = PlayersCurrentPieceName[id]
	
	new pieceSquareWidth = PiecesSquareWidth[pieceName]
	new Array:pieceData = createBiArray(pieceSquareWidth,pieceSquareWidth)
	
	clonePiece(PlayersCurrentPieceData[id],pieceData,PlayersCurrentPiecePosition[id],piecePosition,pieceName);
	
	piecePosition[ROW]++;
	
	return isValidPieceInTable(id,pieceData,piecePosition,pieceName)
}
isValidPieceInTable(id,Array:pieceData,piecePosition[POSITION],PIECE_NAME:pieceName)
{	
	new pieceSquareWidth = PiecesSquareWidth[pieceName];
	
	new positionInPiece[POSITION]
	new positionInTable[POSITION]
	
	for(new i=0;i<pieceSquareWidth;i++)
	{
		positionInPiece[COL] = i		
		positionInTable[COL] = piecePosition[COL] + positionInPiece[COL]
		
		for(new j=0;j<pieceSquareWidth;j++)
		{
			positionInPiece[ROW] = (pieceSquareWidth - 1) - j;
			positionInTable[ROW] = piecePosition[ROW] - j
			
			if(0 <= positionInTable[COL] < TableCols)
			{
				if(getBiArrayCell(pieceData,positionInPiece[ROW],positionInPiece[COL]) && positionInTable[ROW] >= 0)
				{
					if(positionInTable[ROW] < TableRows)
					{
						if(getBiArrayCell(PlayersTables[id],positionInTable[ROW],positionInTable[COL]))
						{
							return false;
						}
					}
					else
					{
						return false;
					}
				}
			}
			else 
			{
				if(getBiArrayCell(pieceData,positionInPiece[ROW],positionInPiece[COL]))
				{
					return false;
				}
			}
		}
	}
	
	return true;
}
putPieceInTable(id)
{
	new pieceSquareWidth = PiecesSquareWidth[PlayersCurrentPieceName[id]];
	
	new positionInPiece[POSITION]
	new positionInTable[POSITION]
	
	for(new i=0;i<pieceSquareWidth;i++)
	{
		positionInPiece[COL] = i
		positionInTable[COL] = PlayersCurrentPiecePosition[id][COL] + i
		
		for(new j=0;j<pieceSquareWidth;j++)
		{
			positionInPiece[ROW] = (pieceSquareWidth - 1) - j;
			positionInTable[ROW] = PlayersCurrentPiecePosition[id][ROW] - j;
			
			if(positionInTable[ROW] < 0)
			{
				return false
			}
			else
			{
				if(getBiArrayCell(PlayersCurrentPieceData[id],positionInPiece[ROW],positionInPiece[COL]))
				{
					setBiArrayCell(PlayersTables[id],positionInTable[ROW],positionInTable[COL],true)
				}
			}			
		}
	}
	
	return true;
}

cleanRow(id)
{	
	for(new row=0;row<TableRows;row++)
	{
		new bool:fullRow = true;
		
		for(new col=0;col<TableCols;col++)
		{
			if(!getBiArrayCell(PlayersTables[id],row,col))
			{
				fullRow = false;
				break;
			}
		}
		
		if(fullRow)
		{
			
			for(new col=0;col<TableCols;col++)
			{
				setBiArrayCell(PlayersTables[id],row,col,false)
			}
			
			return row;
		}
	}
	
	return -1;
}

handleGravityEffect(id,cleanedRow)
{
	for(new col=0;col<TableCols;col++)
	{
		new lowerCleanRow = cleanedRow
		
		for(new row= cleanedRow + 1; row < TableRows ; row++)
		{
			if(!getBiArrayCell(PlayersTables[id],row,col))
			{
				lowerCleanRow = row;
			}
			else
			{
				break;
			}
		}
		
		for(new row = lowerCleanRow - 1; row >= 0; row--)
		{
			if(getBiArrayCell(PlayersTables[id],row,col))
			{
				setBiArrayCell(PlayersTables[id],row,col,false)
				setBiArrayCell(PlayersTables[id],lowerCleanRow,col,true)
			}
			
			lowerCleanRow--
		}		
	}
}

public movePieceDownTask(params[])
{
	new id = params[0]
	
	if(PlayersIsPlaying[id])
	{
		new bool:createTask
		
		if(canMovePieceDown(id))
		{
			PlayersCurrentPiecePosition[id][ROW]++
			createTask = true;
		}
		else
		{
			if(putPieceInTable(id))
			{
				playSound(id,Sounds[FALL]);
				
				new row
				
				do
				{
					row = cleanRow(id)
					
					if(row != -1) 
					{
						playSound(id,Sounds[LINE]);
						
						handleGravityEffect(id,row)
					}				
				}
				while(row != -1);
				
				new PIECE_NAME:pieceName = PlayersNextPieceName[id]
			
				PlayersCurrentPieceData[id] = PlayersNextPieceData[id];
				PlayersCurrentPieceName[id] = pieceName;
				initPiecePosition(PlayersCurrentPiecePosition[id],pieceName);
						
				getRandomPiece(PlayersNextPieceData[id],PlayersNextPiecePosition[id],PlayersNextPieceName[id])
				
				createTask = true;
			}
			else
			{
				playSound(id,Sounds[GAMEOVER]);
				PlayersGameState[id] = GAME_OVER;
				
				destroyBiArray(PlayersTables[id],TableRows)
				
				playerQuitingGame(id);
				
				menuTetris(id);
				
				return
			}
		}
		
		new menu,newmenu
		
		player_menu_info(id,menu,newmenu);
		
		if(newmenu == PlayersMenuInGame[id])
		{
			if(createTask)
			{
				set_task(PlayersTaskDelay[id],"movePieceDownTask",PlayersTaskID[id],params,1,"a",1) 
				menuTetris(id);
			}
		}
		else
		{
			playerQuitingGame(id);
		}
	}
}

public menuTetrisInGamePre(id)
{
	if(!PlayersIsPlaying[id])
	{
		playerEnteringGame(id);
	}
	
	menuTetrisInGame(id);	
}
public menuTetrisInGame(id)
{
	new menu = menu_create("","handleMenuTetrisInGame");
	
	PlayersMenuInGame[id] = menu;	
	
	new TetrisMusic[TETRIS_MUSIC_LEN+1]
	formatex(TetrisMusic,TETRIS_MUSIC_LEN,"%L",LANG_PLAYER, playersMusic[id] ? ML_DefinitionsString[TETRIS_MUSIC_ON] : ML_DefinitionsString[TETRIS_MUSIC_OFF])
	
	new TetrisExit[TETRIS_EXIT_LEN+1]
	formatex(TetrisExit,TETRIS_EXIT_LEN,"%L",LANG_PLAYER,ML_DefinitionsString[TETRIS_EXIT])
	
	menu_additem(menu,TetrisMusic,"1");
	menu_additem(menu,TetrisExit,"2");
	
	menu_addblank(menu,0)
	
	const rowStringLen = 3 * TableCols + 1;
	
	new currentPieceSquareWidth = PiecesSquareWidth[PlayersCurrentPieceName[id]];
	
	new currentPieceEndRow = PlayersCurrentPiecePosition[id][ROW]
	
	new currentPieceStartRow = currentPieceEndRow - currentPieceSquareWidth + 1
	
	new currentPieceStartCol = PlayersCurrentPiecePosition[id][COL]
	new currentPieceEndCol = currentPieceStartCol + currentPieceSquareWidth - 1;
	
	for(new row=0; row < currentPieceStartRow; row++)
	{
		PlayersTableCellActive[id] = false;
		
		new rowString[rowStringLen];
		format(rowString,2,cellCharColors[INACTIVE]);
		
		for(new col = 0;col < TableCols; col++)
		{
			new bool:active = getBiArrayCell(PlayersTables[id],row,col)
			
			if(active != PlayersTableCellActive[id])
			{
				PlayersTableCellActive[id] = active;
				format(rowString,rowStringLen-1,"%s%s",rowString,cellCharColors[CELL_COLOR:active]);
			}
			
			format(rowString,rowStringLen-1,"%s%s",rowString,cellChar);
		}
		
		menu_addtext(menu,rowString,0);
	}
	
	if(0 <= currentPieceEndRow)
	{
		if(currentPieceEndRow >= TableRows)
			currentPieceEndRow = TableRows - 1;
		
		for(new row = currentPieceStartRow; row <= currentPieceEndRow; row++)
		{
			if(row >= 0)
			{
				PlayersTableCellActive[id] = false;
				
				new rowString[rowStringLen];
				format(rowString,2,cellCharColors[INACTIVE]);
				
				for(new col=0;col<currentPieceStartCol;col++)
				{
					new bool:active = getBiArrayCell(PlayersTables[id],row,col)
					
					if(active != PlayersTableCellActive[id])
					{
						PlayersTableCellActive[id] = active;
						format(rowString,rowStringLen-1,"%s%s",rowString,cellCharColors[CELL_COLOR:active]);
					}
					
					format(rowString,rowStringLen-1,"%s%s",rowString,cellChar);
				}
				
				new positionInPiece[POSITION]
				
				if(currentPieceEndCol >= TableCols)
					currentPieceEndCol = TableCols - 1;
				
				positionInPiece[ROW] = row - currentPieceStartRow;
				
				
				for(new col=currentPieceStartCol;col<=currentPieceEndCol;col++)
				{
					if(col >= 0)
					{
						positionInPiece[COL] = col - currentPieceStartCol;
						
						new bool:active = getBiArrayCell(PlayersCurrentPieceData[id],positionInPiece[ROW],positionInPiece[COL]) || getBiArrayCell(PlayersTables[id],row,col)
						
						if(active != PlayersTableCellActive[id])
						{
							PlayersTableCellActive[id] = active;
							format(rowString,rowStringLen-1,"%s%s",rowString,cellCharColors[CELL_COLOR:active]);
						}
						
						format(rowString,rowStringLen-1,"%s%s",rowString,cellChar);
					}
				}
				
				for(new col=currentPieceEndCol+1;col< TableCols;col++)
				{
					new bool:active = getBiArrayCell(PlayersTables[id],row,col)
					
					if(active != PlayersTableCellActive[id])
					{
						PlayersTableCellActive[id] = active;
						format(rowString,rowStringLen-1,"%s%s",rowString,cellCharColors[CELL_COLOR:active]);
					}
					
					format(rowString,rowStringLen-1,"%s%s",rowString,cellChar);
				}
				
				menu_addtext(menu,rowString,0);
			}
		}
	}
	
	for(new row=currentPieceEndRow+1; row < TableRows; row++)
	{
		PlayersTableCellActive[id] = false;
		
		new rowString[rowStringLen];
		format(rowString,2,cellCharColors[INACTIVE]);
		
		for(new col = 0;col < TableCols; col++)
		{
			new bool:active = getBiArrayCell(PlayersTables[id],row,col)
			
			if(active != PlayersTableCellActive[id])
			{
				PlayersTableCellActive[id] = active;
				format(rowString,rowStringLen-1,"%s%s",rowString,cellCharColors[CELL_COLOR:active]);
			}
			
			format(rowString,rowStringLen-1,"%s%s",rowString,cellChar);
		}
		
		menu_addtext(menu,rowString,0);
	}
	
	new TetrisTitle[TETRIS_TITLE_LEN+1]
	formatex(TetrisTitle,TETRIS_TITLE_LEN,"%L",LANG_PLAYER,ML_DefinitionsString[TETRIS_TITLE])
	
	menu_setprop(menu,MPROP_TITLE,TetrisTitle);
	menu_setprop(menu,MPROP_EXITNAME,TetrisExit);
	
	for(new i=3;i<=7;i++)
		menu_addtext(menu,"",1)
	
	menu_display(id,menu,0);
	
}

public handleMenuTetrisInGame(id,menu,item)
{
	if(item >= 0) 
	{
		new access, callback; 
		
		new actionString[2];		
		menu_item_getinfo(menu,item,access, actionString,1,_,_, callback);		
		new action = str_to_num(actionString);	
		
		switch(action)
		{
			case 0:
			{
				playerQuitingGame(id);
			}
			case 1:
			{
				client_cmd(id,"mp3 stop")
				
				playersMusic[id] = !playersMusic[id]
				
				if(playersMusic[id])
					client_cmd(id,"mp3 loop sound/%s",Musics[MUSIC:random(_:MUSIC)] );
				
				menuTetrisInGame(id)
			}
		}
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}	

public menuTetrisGameOver(id)
{
	client_cmd(id,"mp3 stop")
	
	new menu = menu_create("","handleMenuTetrisGameOver");
	
	new tetrisExit[TETRIS_EXIT_LEN+1]
	formatex(tetrisExit,TETRIS_EXIT_LEN,"%L",LANG_PLAYER,ML_DefinitionsString[TETRIS_EXIT])
	
	new tetrisPlayAgain[TETRIS_PLAY_AGAIN_LEN+1]
	formatex(tetrisPlayAgain,TETRIS_PLAY_AGAIN_LEN,"%L",LANG_PLAYER,ML_DefinitionsString[TETRIS_PLAY_AGAIN])
	
	new tetrisTitleFormat[] = "%L^n^n%L"
	const tetrisTitleLen = sizeof tetrisTitleFormat + TETRIS_TITLE_LEN + TETRIS_GAME_OVER_LEN
	new tetrisTitle[tetrisTitleLen+1]
	
	formatex(tetrisTitle,tetrisTitleLen,tetrisTitleFormat,LANG_PLAYER,ML_DefinitionsString[TETRIS_TITLE],LANG_PLAYER,ML_DefinitionsString[TETRIS_GAME_OVER])
	
	menu_setprop(menu,MPROP_TITLE,tetrisTitle);	
	menu_setprop(menu,MPROP_EXITNAME,tetrisExit);
	
	menu_additem(menu,tetrisPlayAgain,"1");
	
	menu_display(id,menu,0);
}

public handleMenuTetrisGameOver(id,menu,item)
{
	if(item >= 0) 
	{
		new access, callback; 
		
		new actionString[2];		
		menu_item_getinfo(menu,item,access, actionString,1,_,_, callback);		
		new action = str_to_num(actionString);	
		
		switch(action)
		{
			case 1:
			{
				PlayersGameState[id] = START
				menuTetris(id);
			}
		}
	}
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}	
