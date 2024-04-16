# Metro-2033-Modding
This repository contains source code for Metro 2033 Board Game Modification for Tabletop Simulator.
Scripts were written using Lua programming language and Tabletop Simulator scripting API. I used Visual Studio Code text editor with "Tabletop Simulator Lua" plugin from rolandostar 
(VS Marketplace Link: https://marketplace.visualstudio.com/items?itemName=rolandostar.tabletopsimulator-lua) to handle separation of scripts into sifferent files.
## Structure
Files located directly in /scripts folder are Object scripts assigned to specific objects in the game.
Files in /scripts/util are utilities which are to be imported into object scripts by VS Code plugin
## VS Code importing
Line
```lua
require("scripts.util.tables")
```
indicate that the content of specified utility file will be imported into this file by VS Code plugin. So in 
Tabletop Simulator scripting window it will just be one file with some dynamically generated code added to it.
Util files contain only some context-independent functions and objects that are useful for object scripts, but 
do not necessarily belong to the objects itself (F.e., Set and Queue data structures). 
## OOP-like interaction between scripts
Tabletop Simulator scripting API is very limited in terms of interaction between different object scripts.
There is no way to add any methods to the objects - you can only use functions that are defined by the API itself. If you need to use function from other object's script, you have to use Object.call() (https://api.tabletopsimulator.com/object/#call), which is absolutely ugly way to call it comparing to what we have in other programming languages. The name of the function should be passed in form of string, and the only possible parameter type is Lua table:
```lua
local obj = getObjectFromGUID(guid)
obj.call('someFunction', {param1=param1, param2=param2})
```
This form of function calling is excessive and too long, not to mention that function we want to call must always receive arguments as table. So it affects the quality of both client and destination scripts.
### Importing functions
To fix this issue I designed a way to kind of "Import" and "Export" needed function so they can later be used in much simpler form:
```lua
local obj = getObjectFromGUID(guid)
obj:someFunction(param1, aram2)
```
So, in the onLoad() function of each script you will often see section separated by "Importing functions" comment. Code inside of that section basically wraps the actual object we want to call with proxy table, adding custom functions that are simply "translating" the call to the form of Object.call() method. Consider next example:
```lua
-- ------------------------------------------------------------
-- Importing functions
-- ------------------------------------------------------------
ADMIN_BOARD = {
    obj = getObjectFromGUID(ADMIN_BOARD_GUID),
    getActiveHeroes = function(self)
        return self.obj.call('getActiveHeroes')
    end
}
-- ------------------------------------------------------------
-- Importing functions end
-- ------------------------------------------------------------
```
Here we kind of "importing" the ADMIN_BOARD object by wrapping the actual object we got from getObjectFromGUID by this table, and adding getActiveHeroes function to it. Function takes an argument self, which should be a reference to this same table, so basic call will look now like this:
```lua
local activeHeroes = ADMIN_BOARD.getActiveHeroes(ADMIN_BOARD)
```
But, Lua also provide a special syntax for these types of scenarios, when the first argument of the function is a reference to the object being called - which is a usage of ":" operator (You might see it in Tabletop Simulator's Vector and Color objects' methods, f.e. https://api.tabletopsimulator.com/vector/#get).
So now, using this method-like syntax we finnaly getting our code to look Object-Oriented:
```lua
local activeHeroes = ADMIN_BOARD:getActiveHeroes()
```
The same mechanizm applies if destination function accepts table or object as a parameter:
```lua
-- ------------------------------------------------------------
-- Importing functions
-- ------------------------------------------------------------
ADMIN_BOARD = {
    obj = getObjectFromGUID(ADMIN_BOARD_GUID),
    assignHero = function(self, heroCard)
        self.obj.call('assignHero', heroCard)
    end
}
-- ------------------------------------------------------------
-- Importing functions end
-- ------------------------------------------------------------
```
The actual call will look like this:
```lua
ADMIN_BOARD:assigHero(heroCard)
```
### Exporting functions
However, if the destination function takes other types of parameters (and also more then 1 parameter), this thing wouldn't work in the same way because Object.call accepts ONLY table and ONLY 1. The possible solution 
may be just for that funciton to have only 1 parameter, which will be the table containing all parameters, but I personally don't like this approach because of 2 reasons:
1. It increases length of parameters in both destination function and also client code
2. If that function is used by both its own script and other script as well, then I don't like the idea that I need to modify the function signature just because some other object want to call it. I want function to remain the same and accept parameters as a table only when there is a logical reason behind it.

That's why I also added the way to "export" functions. At the end of object scripts you usually will see section like this:
```lua
-- ------------------------------------------------------------
-- Exporting functions
-- ------------------------------------------------------------

function equipmentCountExported(args)
    return equipmentCount(args.hero_name, args.equip_name)
end
```
So at the end of the files I basically declaring a duplicate function with "..Exported" suffix which accepts obly one table parameter - args. Those parameters are then passed to normal function respectively. Then, in the "importing part" of other script, this exported function name will be specified as an argument to the Object.call() method:
```lua
-- ------------------------------------------------------------
-- Importing functions
-- ------------------------------------------------------------
ADMIN_BOARD = {
    obj = getObjectFromGUID(ADMIN_BOARD_GUID),
    equipmentCount = function(self, hero_name, equip_name)
        return self.obj.call('equipmentCountExported', {hero_name=hero_name, equip_name=equip_name})
    end
}
-- ------------------------------------------------------------
-- Importing functions end
-- ------------------------------------------------------------
```
So then the function can be called like this in importer object script:
```lua
local count = ADMIN_BOARD:equipmentCount('anna', 'shotgun')
```
I understand that this approach requires some extra code to be written, but I still prefer it much more then using that weird call() method. It feels much cleaner to me to have that wrapping and mapping functionality separated at the end of the file and in the onLoad() event, so then in the rest of the code we can get self-explanatory method call like in other programming languages. Hope this helps clarify what you will see a lot in scripts of this modification.