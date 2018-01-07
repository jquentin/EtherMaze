pragma solidity ^0.4.17;

contract owned {
    function owned() { owner = msg.sender; }
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract EtherMaze is owned {
    
    enum Direction { West, East, South, North }
    
    struct Player
    {
        bool isRegistered;
        Position position;
    }
    
    struct Position
    {
        uint8 x;
        uint8 y;
    }
    
    uint8 mazeSize;
    uint256 mazeDescrBin;
    Position initPos;
    Position treasurePos;
    uint moveCost;
    bool treasureIsFound;
    address winner;
    
    mapping (address => Player) players;

    function EtherMaze()
    {
        treasureIsFound = true;
    }
    
    function CreatNewMaze(uint8 size, uint8 initX, uint8 initY, uint8 treasureX, uint8 treasureY, uint8 _moveCostInFinney, uint256 descr) onlyOwner payable
    {
        if(!treasureIsFound)
            revert();
        
        mazeSize = size;
        mazeDescrBin = descr;
        initPos.x = initX;
        initPos.y = initY;
        treasurePos.x = treasureX;
        treasurePos.y = treasureY;
        moveCost = _moveCostInFinney * 1000000000000000;
        
        if (!IsTreasureAccessible())
            revert();
            
        treasureIsFound = false;
    }

    modifier sentEnoughCashForMove()
    {
        if (msg.value < moveCost)
            throw;
        else
            _;
    }
    
    function CanGo(Position position, Direction direction) internal constant returns (bool canGo)
    {
        if (direction == EtherMaze.Direction.West && position.x == 0
            || direction == EtherMaze.Direction.East && position.x == mazeSize - 1
            || direction == EtherMaze.Direction.North && position.y == 0
            || direction == EtherMaze.Direction.South && position.y == mazeSize - 1)
            return false;
        if (direction == EtherMaze.Direction.West)
            return mazeDescrBin & (uint256(1) << (mazeSize - 1) * position.y + position.x - 1) > 0;
        if (direction == EtherMaze.Direction.East)
            return mazeDescrBin & (uint256(1) << (mazeSize - 1) * position.y + position.x) > 0;
        if (direction == EtherMaze.Direction.North)
            return mazeDescrBin & (uint256(1) << (mazeSize - 1) * (mazeSize) + (mazeSize - 1) * position.x + position.y - 1) > 0;
        if (direction == EtherMaze.Direction.South)
            return mazeDescrBin & (uint256(1) << (mazeSize - 1) * (mazeSize) + (mazeSize - 1) * position.x + position.y) > 0;
    }
    
    function CanGo(Direction direction) internal constant returns (bool canGo)
    {
        return CanGo(players[msg.sender].position, direction);
    }
    
    //// Backtracking for checking accessibility //////
    Position[] visitedPositions;
    
    function HasAlreadyBeenVisited(Position pos) internal constant returns (bool alreadyVisited)
    {
        for (uint8 i = 0 ; i < visitedPositions.length ; i++)
        {
            if (visitedPositions[i].x == pos.x && visitedPositions[i].y == pos.y)
                return true;
        }
        return false;
    }
    
    function IsTreasureAccessible() internal returns (bool isAccessible)
    {
        visitedPositions.length = 0;
        return IsTreasureAccessibleFrom(initPos);
    }
    
    function IsTreasureAccessibleFrom(Position from) internal returns (bool isAccessible)
    {        
        if (HasAlreadyBeenVisited(from))
            return false;
        visitedPositions.push(from);
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
    //// End Backtracking for checking accessibility //////
    
    function LookAround() constant returns (bool canGoWest, bool canGoEast, bool canGoNorth, bool canGoSouth)
    {
        if(!players[msg.sender].isRegistered)
            revert();
        return (CanGo(EtherMaze.Direction.West), CanGo(EtherMaze.Direction.East), CanGo(EtherMaze.Direction.North), CanGo(EtherMaze.Direction.South));
    }

    function GetCurrentTreasureValueInFinney() constant returns (uint32)
    {
    	return (uint32) (this.balance / 1000000000000000);
    }

    function GetMoveCostInFinney() constant returns (uint32)
    {
    	return (uint32) (moveCost / 1000000000000000);
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
        treasureIsFound = true;
        winner = msg.sender;
        msg.sender.transfer(this.balance);
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
    
    function Go(Direction direction) internal returns (string result)
    {
        if(treasureIsFound)
        {
            return "This maze is empty. The treasure has been found.";   
        }
        if(!players[msg.sender].isRegistered)
        {
            return "Not Registered";
        }
        bool hasMoved = Move(direction);
        if (!hasMoved)
        	return "Cannot move to this direction";
        if (FoundTreasure())
            return "You found the treasure!!";
        return "Move complete";
    }
    
    function GoWest() payable sentEnoughCashForMove() returns (string result)
    {
        return Go(EtherMaze.Direction.West);
    }
    
    function GoEast() payable sentEnoughCashForMove() returns (string result)
    {
        return Go(EtherMaze.Direction.East);
    }
    
    function GoNorth()  payable sentEnoughCashForMove() returns (string result)
    {
        return Go(EtherMaze.Direction.North);
    }
    
    function GoSouth()  payable sentEnoughCashForMove() returns (string result)
    {
        return Go(EtherMaze.Direction.South);
    }

}
