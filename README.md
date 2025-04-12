remotely controlled mining turtles for the CC:Tweaked mod

- chunk based mapping, pathfinding and live updates
- performant message streaming using its own protocol (like MQTT but for bidirectional streaming)
- optimal mining strategies
- remote gui control on the host

  
THIS IS WORK IN PROGRESS.  
Let me know about any issues you have or ideas. :)  
  

# Installation:

### GPS:  

Before setting up the actual Computers, GPS should be available. Place it somewhere near the Host Computer.  
https://tweaked.cc/guide/gps_setup.html  

### HOST COMPUTER:

1. Place the Host-Computer with a Wireless Modem and Monitor next to it
   ( I recommend the monitors facing south, so the map is aligned more intuitively )
3. Download and run the installation using those commands:  
>  pastebin get https://pastebin.com/pU2HBysT install  
>  install  
3. Setup the Stations for the Turtles:
    1. Open lua
    2. Delete existing Stations:
      > global.deleteAllStations()  
    3.  Add new Stations:
      > global.addStation(x, y, z, facing, type)  
   facing = "north", "west", "south", "east"  
   type = "turtle" for home and dropoff, "refuel" for refueling
4.  Save Config:
  > global.saveConfig()  

![grafik](https://github.com/user-attachments/assets/b37d059c-8b09-4d74-8bf2-eb3a31dfa35d)


### TURTLES:

1.  Place Turtle anywhere, with a Wireless Modem and some Fuel
2.  Install using pastebin ( see Host, same file )
   Turtle should request a Station from Host and move there

After having placed all turtles and they moved to their station, reboot the host using the reboot button.
This saves the station assignments for each turtle.

Done

![grafik](https://github.com/user-attachments/assets/e493f9d3-a631-4364-aff3-c813791652b8)
![grafik](https://github.com/user-attachments/assets/224e47a3-88e6-428c-8a6d-2c7643ce7ddb)
