# Game Design Document: Online Sichuan Mahjong

## Introduction

This document outlines the design for an online adaptation of Sichuan Mahjong, developed in English, to be played over a Local Area Network (LAN) with support for up to 4 players. The game retains the core essence of traditional Sichuan Mahjong while introducing modern features such as multiple game modes and an in-game currency system for betting. It is designed to be accessible to both new players and experienced Mahjong enthusiasts, offering an engaging and social gaming experience.

---

## Game Mechanics

### Tiles and Setup
- **Tile Set**: The game uses a standard Sichuan Mahjong set of 144 tiles, consisting of:
  - **Suits**: Bamboo (Bams), Characters (Craks), Dots
  - **Honors**: Winds (East, South, West, North), Dragons (Red, Green, White)
  - **Bonus Tiles**: Flowers, Seasons
- **Initial Setup**: Tiles are shuffled and arranged into a wall. Each player receives 13 tiles, with the dealer (East) receiving an extra tile to start.

### Turns and Actions
- **Turn Structure**: Players take turns in a clockwise order:
  1. Draw a tile from the wall.
  2. Discard a tile to maintain a hand of 13 tiles (unless forming a Kong, which increases the hand size temporarily).
- **Objective**: Form a winning hand, typically consisting of:
  - Four sets (Pongs, Kongs, or Chows)
  - One pair (two identical tiles)
- **Special Moves**:
  - **Pong**: Claim a discarded tile to form three identical tiles.
  - **Kong**: Claim a discarded tile or use a drawn tile to form four identical tiles (requires drawing an additional tile from the wall).
  - **Chow**: Claim a discarded tile to form three consecutive tiles of the same suit (only available to the next player in turn order).
- **Winning**: A player declares "Mahjong" when their hand meets the winning criteria, ending the round.

### Scoring and Rounds
- **Scoring**: Points are awarded based on the value of the winning hand (e.g., specific combinations or patterns).
- **Rounds**: A full game consists of multiple hands, traditionally 16 (four rounds, each with four hands), with the dealer rotating after each hand unless they win.

---

## Networking

### LAN Support
- **Connection**: The game operates over a LAN, supporting up to 4 players. One player acts as the host, creating a session that others join using the host’s IP address.
- **Architecture**: Uses a peer-to-peer model for simplicity, with the host managing game logic and synchronization.

### Synchronization
- **Game State**: Tile draws, discards, and player actions are synchronized across all clients to ensure consistency. The host broadcasts updates to all connected players.
- **Latency Handling**: Basic latency compensation ensures smooth gameplay over a local network.

### Player Interaction
- **Chat Feature**: An in-game chat window allows players to communicate, enhancing the social experience.

---

## Game Modes

The game offers multiple modes to cater to different play styles:

### Standard Mode
- **Description**: Follows traditional Sichuan Mahjong rules with 16 hands (four rounds).
- **Duration**: Suitable for a full, traditional experience.

### Quick Mode
- **Description**: A shorter variant with 8 hands (two rounds).
- **Purpose**: Ideal for players seeking a faster session.

### Special Rules Mode
- **Description**: Introduces unique variations, such as:
  - **All Winds and Dragons**: Only honor tiles (Winds and Dragons) are used.
  - **Pure Suit**: Players must form hands using tiles from a single suit.
- **Purpose**: Adds variety and challenge for experienced players.

---

## In-Game Currency

### Currency System
- **Starting Amount**: Each player begins with 1000 virtual points (no real-money transactions).
- **Betting**: Before each game, players agree on a bet amount (e.g., 100 points), deducted from their balance and added to a central pot.

### Betting and Payouts
- **Payout**: The winner of the game receives the entire pot.
- **Ties**: In case of a tie, the pot is split equally among the winners.

### Currency Management
- **Earning Currency**: Players can gain additional points by winning games or completing in-game achievements (e.g., "Win 5 games" = 500 points).
- **Purpose**: Encourages replayability and competition without real-world financial stakes.

---

## User Interface

### Main Menu
- **Options**:
  - Start a new game (host)
  - Join an existing game (client)
  - Settings (volume, display)
  - Rules (tutorial/help)

### Game Screen
- **Layout**:
  - **Player Hand**: Displays the player’s tiles at the bottom, clickable for discarding.
  - **Discard Pile**: Central area showing discarded tiles, clickable for claiming.
  - **Wall**: Visual representation of remaining tiles.
  - **Opponent Hands**: Simplified view of other players’ tile counts (hidden tiles).
- **Interactive Elements**: Buttons for drawing, discarding, and claiming tiles (Pong, Kong, Chow, Mahjong).

### Chat Window
- **Location**: Sidebar for text communication during gameplay.

### Scoreboard
- **Details**: Displays each player’s current score and currency balance, updated after each hand.

---

## Technical Requirements

### Platform
- **Supported OS**: Windows, macOS, Linux
- **Cross-Platform**: Built using a compatible game engine or language (e.g., Unity, Godot, or custom C++ with SDL).

### Hardware
- **Minimum Specs**: Standard computer with LAN capabilities (Ethernet or Wi-Fi).
- **No Additional Requirements**: Relies on basic system resources.

### Software
- **Development Tools**: [Insert engine/language here, e.g., Unity with C#].
- **Networking**: Utilizes standard LAN protocols for peer-to-peer communication.

---

## Conclusion

This game design document provides a comprehensive blueprint for an online Sichuan Mahjong game tailored for LAN play. By combining traditional gameplay with modern features like multiple modes and a betting system, it offers a rich, engaging experience for up to 4 players. The focus on simplicity in networking and an intuitive UI ensures accessibility, while the in-game currency adds a layer of excitement and replayability.

## Implementation Notes

- **Development Approach**: This game will be developed by a single developer with no strict timeline.
- **Feature Priority**: All features described in this document are considered "must-have" for the complete implementation.
- **Asset Creation**: Initial implementation will use simple placeholder assets that correctly represent the tiles and game elements without fancy graphics.
- **Distribution**: The game will be distributed as a Godot project.