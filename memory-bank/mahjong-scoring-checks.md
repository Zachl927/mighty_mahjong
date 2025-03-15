# Sichuan Mahjong Winning Conditions and Scoring

## Winning Conditions

In Sichuan Mahjong, a player wins by achieving one of these hand patterns:

### 1. Standard Pattern (Hu)
- Four sets (pongs or chows) and one pair
- **Total of 14 tiles**
- Following the two-suit restriction (only tiles from at most 2 suits)

### 2. Seven Pairs (Qi Dui)
- Seven distinct pairs of identical tiles
- **Total of 14 tiles**
- Following the two-suit restriction
- All tiles must be concealed (no exposed sets)

## Turn Order Rules
1. Players take turns in a counter-clockwise direction
2. On a player's turn, they must first draw a tile
3. After drawing, the player must discard one tile
4. When a player discards, others can claim for pong, gang, or winning
5. Claiming interrupts the normal turn order (player who claims gets the next turn)
6. If no one claims, turn passes to the next player

## Additional Rules for Actions

### Draw Action
- Valid only when it's the player's turn
- Valid only when the player's hand has less than 14 tiles
- Draw from wall if available

### Discard Action
- Valid only when it's the player's turn
- Valid only after drawing (so player must have 14 tiles)
- Player must discard one tile (cannot skip discarding)

### Pong Action (Claiming 3 of a kind)
- Valid when another player discards a tile
- Valid when the claiming player has at least 2 identical tiles
- Results in an exposed set of 3 identical tiles

### Gang Action (Claiming 4 of a kind)
- **Concealed Gang**: When a player has 4 identical tiles in their hand
- **Exposed Gang**: When a player has a pong (3 tiles) and either draws or claims the 4th identical tile
- After completing a gang, player must draw an extra tile from the back of the wall

### Win Action
- Can be claimed on any discard that completes the winning pattern
- Can also be claimed after drawing a tile that completes the winning pattern (self-draw)

## Scoring System

Sichuan Mahjong typically uses a simplified scoring system:

### Base Points
- **Self-drawn win**: 2 points
- **Winning from discard**: 1 point

### Bonus Points
- **All Pongs (No Chows)**: +1 point
- **Clean Hand** (one suit only): +1 point
- **All Concealed** (no exposed sets): +1 point
- **Seven Pairs**: +2 points

### Special Hands
- **Pure One Suit**: +2 points
- **All Pongs of One Suit**: +3 points
- **Little Three Dragons** (two dragon pongs and one dragon pair): +2 points

## Pattern Checking Algorithm

To check if a hand forms a valid winning pattern:

1. **Standard Pattern Check**:
   - Count all exposed sets
   - For the remaining concealed tiles:
     - Try forming all possible combinations of pongs and chows
     - Check if any combination results in exactly 4 sets and 1 pair
   - Use a recursive algorithm to try all possibilities

2. **Seven Pairs Check**:
   - Check that the hand has no exposed sets
   - Group identical tiles and verify there are exactly 7 pairs
   - Ensure no leftover tiles

## Implementation Notes

- Use depth-first search for pattern checking
- Keep track of visited patterns to avoid duplicate checks
- Consider separate classes for pattern checking to maintain modularity