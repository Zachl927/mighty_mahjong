# Tech Stack

- **Game Engine**: Godot  
- **Programming Language**: GDScript  
- **Networking**: Godot's built-in networking with ENet  
- **Database**: SQLite for local data storage  

### Why This Stack?
This combination provides a straightforward and reliable solution tailored to the game's requirements. Here's the breakdown:

#### Game Engine: Godot
- **Why Godot?**  
  Godot is a lightweight, open-source game engine perfect for 2D games like Mahjong, which relies on tile-based graphics rather than complex 3D rendering. It supports Windows, macOS, and Linux out of the box, ensuring cross-platform compatibility. Its simplicity reduces development overhead while still offering powerful tools for game creation.

#### Programming Language: GDScript
- **Why GDScript?**  
  GDScript is Godot's built-in scripting language, designed specifically for ease of use in game development. With a Python-like syntax, it’s approachable and efficient for coding Mahjong’s game logic—such as tile management, scoring, and multiplayer interactions—without unnecessary complexity.

#### Networking: Godot's Built-in Networking with ENet
- **Why This Approach?**  
  The game requires LAN-based peer-to-peer play for up to 4 players. Godot’s built-in networking, powered by ENet (a reliable UDP library), handles this seamlessly. It ensures low-latency synchronization of game states—like tile draws and discards—across players on a local network, making it both simple to implement and robust for real-time gameplay.

#### Database: SQLite
- **Why SQLite?**  
  With an in-game currency system for betting, you need a way to store player data, such as balances, locally on each player’s machine. Since the game is LAN-based and doesn’t require online persistence, SQLite is an ideal choice. It’s lightweight, file-based, and easy to integrate, providing a no-fuss solution for managing data without the need for a full server setup.

### Why Is This the Simplest Yet Most Robust?
- **Simplicity**: Godot and GDScript have gentle learning curves and reduce setup time. The built-in networking eliminates the need for external libraries, and SQLite requires minimal configuration.
- **Robustness**: Godot is a proven engine for 2D games, ENet ensures reliable LAN connectivity, and SQLite handles data storage efficiently. Together, they meet all the game’s needs—cross-platform support, multiplayer functionality, and currency management—without overcomplicating the stack.

---