pragma solidity ^0.4.17;

import "github.com/Arachnid/solidity-stringutils/strings.sol";

contract EtherMaze {
    
    using strings for *;
    
    enum Direction { West, East, South, North }
    
    struct Player
    {
        bool isRegistered;
        Position position;
    }
    
    struct Position
    {
        uint x;
        uint y;
    }
    
    uint mazeSize;
    uint8[] mazeDescr;
    Position initPos;
    Position treasurePos;
    uint moveCost;
    bool treasureIsFound;
    address winner;
    
    mapping (address => Player) players;

    event log(string s);

    function EtherMaze(uint size, uint initX, uint initY, uint treasureX, uint treasureY, uint _moveCostInFinney, uint8[] descr) payable
    {
        //this.maze = maze;
        mazeSize = size;
        mazeDescr = descr;
        initPos.x = initX;
        initPos.y = initY;
        treasurePos.x = treasureX;
        treasurePos.y = treasureY;
        moveCost = _moveCostInFinney * 1000000000000000;
    }


    modifier sentEnoughCashForMove()
    {
        if (msg.value < moveCost)
            throw;
        else
            _;
    }
    
    function StringToDirection(string s) internal returns (Direction)
    {
        if (sha3(s) == sha3("West"))
            return EtherMaze.Direction.West;
        if (sha3(s) == sha3("East"))
            return EtherMaze.Direction.East;
        if (sha3(s) == sha3("North"))
            return EtherMaze.Direction.North;
        if (sha3(s) == sha3("South"))
            return EtherMaze.Direction.South;
    }
    
    function addressToString(address x) internal returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    
    function CanGo(Position position, Direction direction) internal returns (bool canGo)
    {
        if (direction == EtherMaze.Direction.West && position.x == 0
            || direction == EtherMaze.Direction.East && position.x == mazeSize - 1
            || direction == EtherMaze.Direction.North && position.y == 0
            || direction == EtherMaze.Direction.South && position.y == mazeSize - 1)
            return false;
        if (direction == EtherMaze.Direction.West)
            return mazeDescr[(mazeSize - 1) * position.y + position.x - 1] > 0;
        if (direction == EtherMaze.Direction.East)
            return mazeDescr[(mazeSize - 1) * position.y + position.x] > 0;
        if (direction == EtherMaze.Direction.North)
            return mazeDescr[(mazeSize - 1) * (mazeSize) + (mazeSize - 1) * position.x + position.y - 1] > 0;
        if (direction == EtherMaze.Direction.South)
            return mazeDescr[(mazeSize - 1) * (mazeSize) + (mazeSize - 1) * position.x + position.y] > 0;
    }
    
    function CanGo(Direction direction) internal returns (bool canGo)
    {
        return CanGo(players[msg.sender].position, direction);
    }
    
    function CanGoToString(Direction direction) internal returns (string canGo)
    {
        if (CanGo(direction))
            return "OK";
        else
            return "NO";
    }
    
    
    function IsTreasureAccessible() returns (bool isAccessible)
    {
        return IsTreasureAccessibleFrom(initPos);
    }
    
    function IsTreasureAccessibleFrom(Position from) internal returns (bool isAccessible)
    {
        if (from.x == treasurePos.x && from.y == treasurePos.y)
            return true;
        if (CanGo(from, EtherMaze.Direction.West) && IsTreasureAccessibleFrom(Position({x:from.x-1, y:from.y})))
            return true;
        if (CanGo(from, EtherMaze.Direction.East) && IsTreasureAccessibleFrom(Position({x:from.x+1, y:from.y})))
            return true;
        if (CanGo(from, EtherMaze.Direction.North) && IsTreasureAccessibleFrom(Position({x:from.x, y:from.y-1})))
            return true;
        if (CanGo(from, EtherMaze.Direction.South) && IsTreasureAccessibleFrom(Position({x:from.x, y:from.y+1})))
            return true;
            
        return false;
    }
    
    function LookAround() constant returns (string around)
    {
        if(!players[msg.sender].isRegistered)
            return "Not Registered";
        var res = "West:";
        res = res.toSlice().concat(CanGoToString(EtherMaze.Direction.West).toSlice());
        res = res.toSlice().concat(" ; East:".toSlice());
        res = res.toSlice().concat(CanGoToString(EtherMaze.Direction.East).toSlice());
        res = res.toSlice().concat(" ; North:".toSlice());
        res = res.toSlice().concat(CanGoToString(EtherMaze.Direction.North).toSlice());
        res = res.toSlice().concat(" ; South:".toSlice());
        res = res.toSlice().concat(CanGoToString(EtherMaze.Direction.South).toSlice());
        return res;
    }

    function GetCurrentTreasureValue() constant returns (uint)
    {
    	return this.balance;
    }

    function GetMoveCost() constant returns (uint)
    {
    	return moveCost;
    }
    
    function FoundTreasure() internal returns (bool)
    {
        Position cell = players[msg.sender].position;
        if (cell.x == treasurePos.x && cell.y == treasurePos.y)
            return true;
        else
            return false;
    }
    
    function GetTreasure() internal
    {
        msg.sender.send(this.balance);
        treasureIsFound = true;
        winner = msg.sender;
    }
    
    function Move(Direction direction) internal returns (bool hasMoved)
    {
        Position cell = players[msg.sender].position;
        if (!CanGo(direction))
            return false;
        if (direction == EtherMaze.Direction.West)
            cell.x--;
        if (direction == EtherMaze.Direction.East)
            cell.x++;
        if (direction == EtherMaze.Direction.North)
            cell.y--;
        if (direction == EtherMaze.Direction.South)
            cell.y++;
            
        if (FoundTreasure())
            GetTreasure();
        
        return true;
    }
    
    function Register()
    {
        players[msg.sender].isRegistered = true;
        players[msg.sender].position.x = initPos.x;
        players[msg.sender].position.y = initPos.y;
    }
    
    function GoWest() payable sentEnoughCashForMove() returns (string around)
    {
        if(treasureIsFound)
        {
        	log("This maze is empty. The treasure has been found by ".toSlice().concat(addressToString(winner).toSlice()));
            return "This maze is empty. The treasure has been found by ".toSlice().concat(addressToString(winner).toSlice());   
        }
        if(!players[msg.sender].isRegistered)
        {
        	log("Not Registered");
            return "Not Registered";
        }
        bool hasMoved = Move(EtherMaze.Direction.West);
        if (!hasMoved)
        	return "Cannot move to this direction";
        if (FoundTreasure())
            return "You found the treasure!!";
        return LookAround();
    }
    
    function GoEast() payable sentEnoughCashForMove() returns (string around)
    {
        if(treasureIsFound)
        {
        	log("This maze is empty. The treasure has been found by ".toSlice().concat(addressToString(winner).toSlice()));
            return "This maze is empty. The treasure has been found by ".toSlice().concat(addressToString(winner).toSlice());   
        }
        if(!players[msg.sender].isRegistered)
        {
        	log("Not Registered");
            return "Not Registered";
        }
        bool hasMoved = Move(EtherMaze.Direction.East);
        if (!hasMoved)
        	return "Cannot move to this direction";
        if (FoundTreasure())
            return "You found the treasure!!";
        return LookAround();
    }
    
    function GoNorth()  payable sentEnoughCashForMove() returns (string around)
    {
        if(treasureIsFound)
        {
        	log("This maze is empty. The treasure has been found by ".toSlice().concat(addressToString(winner).toSlice()));
            return "This maze is empty. The treasure has been found by ".toSlice().concat(addressToString(winner).toSlice());   
        }
        if(!players[msg.sender].isRegistered)
        {
        	log("Not Registered");
            return "Not Registered";
        }
        bool hasMoved = Move(EtherMaze.Direction.North);
        if (!hasMoved)
        	return "Cannot move to this direction";
        if (FoundTreasure())
            return "You found the treasure!!";
        return LookAround();
    }
    
    function GoSouth()  payable sentEnoughCashForMove() returns (string around)
    {
        if(treasureIsFound)
        {
        	log("This maze is empty. The treasure has been found by ".toSlice().concat(addressToString(winner).toSlice()));
            return "This maze is empty. The treasure has been found by ".toSlice().concat(addressToString(winner).toSlice());   
        }
        if(!players[msg.sender].isRegistered)
        {
        	log("Not Registered");
            return "Not Registered";
        }
        bool hasMoved = Move(EtherMaze.Direction.South);
        if (!hasMoved)
        	return "Cannot move to this direction";
        if (FoundTreasure())
            return "You found the treasure!!";
        return LookAround();
    }

}