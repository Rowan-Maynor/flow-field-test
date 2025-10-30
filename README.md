I ran in to a huge issue with Conjure where if many units are trying to move at once, the game slows to a halt and breaks. This happens because every unit has a navigation agent that is constantly being updated on tick (lmao). And to make matters worse, the navigation mesh solution I came up with involves constantly rebaking the nav mesh every time a unit stops moving so units can properly path around eachother (lmao x2).

After some research I found out that this is a very common issue with RTS style games like mine, and one that was improved upon dramatically by a "flow field" navigation system. This uses a grid structure along with dijkstra's algorithm to find a global path to the target, then designates a flow direction for every cell in the grid based on what the lowest "cost" was to reach the end goal point.

This should allow me to move many units to a target location indicated by the player, without having to trim and rebake a nav mesh over and over, or have 100's of constantly updating nav agents at any point in time.


<img width="1706" height="939" alt="flow_field_example" src="https://github.com/user-attachments/assets/6fc824a6-8c11-4572-86b4-47361abd6236" />

The above example has blue lines showing the flow direction of every tile, and also has a slight red hue based on the tiles cost.
