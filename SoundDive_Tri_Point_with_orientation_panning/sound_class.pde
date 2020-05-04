class Sound {
  float x, y, z; // Coordinates
  float speedX, speedY, speedZ; // Movement speeds
  String name; // Name
  color debug_color; // Color shown on display

  float distanceToPlayer; // Distance to player, used for volume
  float distanceStroke; // Strokewidth to show distance
  float distanceThreshold = 0; // Distance threshold, used for when to trigger sound
  boolean soundPlaying = false; // Check if player has triggered sound
  boolean positionFound = false; // Check if we've located the sound (Cardinal direction in relation to sketch center);
  boolean moving = false; // Check if object is currently moving.
  boolean startled = false;
  boolean playerClose;
  
  String panning = "Center"; // Helper debug value used to check whether our panning logic works.
  
  String shape = "Circle"; // Defaults to circle, can be changed to Rectangle for larger sounds. Requires extra coords.
  String type = "Static";
  
  // MIDI specific
  int channel; // Channel for the MIDI note
  int action; // Action for the MIDI note.
  int value; // Value for the MIDI note.
  
  /*
    A sound in Ableton has it's own track, and the channel variable corresponds, so; track 1 = channel 1
    The action is what we're doing to the sound. 
      1 = turn on or off
      2 = volume
      3 = panning
      4 = launch clip.
      
      These action numbers are offset by 4, when channels exceed 16 eg:
      1 = 5, turn on or off
      2 = 6, volume
      3 = 7, panning
      4 = 8, launch clip
      
    The value is usually a number between 1 and 127, and tells Ableton what to do.
    
    Examples:
      Channel 1, Action 2 and Value 127 means: turn track 1 up to max volume.
      Channel 3, Action 1 and Value 0 means: turn track 3 off.
      Channel 2, action 3 and Value 60 means: pan track 2 in between L(1) and R(127).
      
      Channel 1, Action 5 and Value 127 means: turn track 1+16 (17) up to max volume.
  */
  
  // Constructor
  Sound(String soundName, color soundColor, float soundX, float soundY, float soundZ, float threshold, int soundChannel) {
    name = soundName;
    debug_color = soundColor;
    x = soundX;
    y = soundY;
    z = soundZ;
    playerClose = false;
    if (threshold != 0){
      distanceThreshold = threshold;
    }
    else{
      distanceThreshold = 100;
    }
    channel = soundChannel;
  }

  // Is player at same Z or close?
  void playerClose(){
    if (z != 99){
      if (playerPosition.z == z || playerPosition.z > z && playerPosition.z < z + 3 || playerPosition.z < z && playerPosition.z > z - 3){
        playerClose = true;
      }
      else{
        playerClose = false;
      }
    }
    if (z == 99) playerClose = true;
  }

  // Draw color
  void drawCircle(int colorDiameter){
    playerClose();
    if (playerClose){
      shape = "Circle";
      noStroke();
      fill(debug_color);
      circle(x,y,colorDiameter);
      
      stroke(debug_color);
      strokeWeight(1);
      noFill();
      circle(x,y,distanceThreshold*2);
      
      if (distanceLines){
        strokeWeight(abs(distanceStroke));
        stroke(debug_color);
        line(x,y,playerPosition.x,playerPosition.y);
      }
    }
    else{
      if (type == "Drone") println("Not close to ", name);
    }
  }
  
  void drawRectangle(int rectWidth, int rectHeight){
    playerClose();
    if (playerClose){
      shape = "Rectangle";
      noStroke();
      fill(debug_color);
      rect(x,y,rectWidth,rectHeight);
    }
  }
  
  // Movement
  void startMove(float xSpeed, float ySpeed, float zSpeed){
    if (moving == false){
      speedX = xSpeed;
      speedY = ySpeed;
      speedZ = zSpeed;
      moving = true;
    }
  }
  
  void move(float x1, float y1, float z1, float x2, float y2, float z2){

    if (moving == true){    
      if (x == x2) speedX = -speedX;
      if (x < x1)  speedX = -speedX;
      if (x > x2) speedX = -speedX;
      
      if (y == y2) speedY = -speedY;
      if (y < y1)  speedY = -speedY;
      
      if (z == z2) speedZ = -speedZ;
      if (z < z1)  speedZ = -speedZ;
      
      x += speedX;
      y += speedY;
      z += speedZ;
    }
    
    if (name == "Cable Drone"){ // y is 430
      if(distanceToPlayer <= (distanceThreshold / 2) - 90 && playerPosition.y == y || distanceToPlayer <= (distanceThreshold / 2) - 90 && (y - 5) > playerPosition.y || distanceToPlayer <= (distanceThreshold / 2) - 90 && (y + 5) < playerPosition.y){
        stopMove();
      }
      else{
        if (playerPosition.x <= x){
          startMove(1, 0 , 0);
        }
        else{
          startMove(-1,0,0);
        }
      }
    }
  }
  
  void stopMove(){
    if (moving == true){
      println("Stopped movement");
      speedX = 0;
      speedY = 0;
      speedZ = 0;
      moving = false;
      if (name == "Cable Drone") cableDroneScan.playTrack(false);
    }
  }

  void setPlaybackSpeed(int speed){
    println("Setting ", name, " to speed ", speed);
  }

  // Distance handling
  void getDistance(){
    // Get raw distance
    if (shape == "Circle"){
      distanceToPlayer = dist(x,y,playerPosition.x, playerPosition.y);
      // If distance is within threshold for sound, continue on. If not, mute the sound.
      if (distanceToPlayer <= distanceThreshold && playerClose){
        
        // Map distance between 1 and 127 for MIDI control
        // Note this is reversed, so shorter distance equals louder volume
        float distanceMapped = distanceMapped = map(distanceToPlayer, 0, 300, 127, 1); 
        if (type == "Drone Trail") distanceMapped = map(distanceToPlayer, 0, 300, 127, 60);
        
        if (name == "Bubble Elevator Down" || name == "Bubble Elevator Up") distanceMapped = map(distanceToPlayer, 0, 300, 70, 1);
        
        // Activate track in Ableton if it's not already enabled
        if (soundPlaying == false){
          //println("Player is within threshold");
          if (type != "Drone") toggleTrack(soundPlaying);
          if (type == "Drone") playTrack(false);
          soundPlaying = true;
        
        } 
        if (soundPlaying){
          // Send volume change to Ableton
          volumeChange(distanceMapped);
        }
        
      }
      else{
        if (soundPlaying == true){
          //println("Player left threshold");
          // Mute track in Ableton
          if (type != "Drone") toggleTrack(soundPlaying);
          if (type == "Drone") playTrack(true);
          soundPlaying = false;
        }
        
      }
    }
    if (shape == "Rectangle"){
      if (x == 0){
        if (playerPosition.x > x && playerPosition.y > y - distanceThreshold || playerPosition.x > x && playerPosition.y < y + distanceThreshold){
          // Activate track in Ableton if it's not already enabled
          if (soundPlaying == false){
            toggleTrack(soundPlaying);
            soundPlaying = true;
          
          } 
          if (soundPlaying){
            // Send volume change to Ableton
            if (playerPosition.y <= y){
              float distance = y - playerPosition.y;
              float distanceMapped = map(distance, 0, 30, 127, 1);
              volumeChange(distanceMapped);
            }
            if (playerPosition.y > y){
              float distance = playerPosition.y - y;
              float distanceMapped = map(distance, 0, 30, 127, 1);
              volumeChange(distanceMapped);
            }
            if (playerPosition.z-2 > z){
              volumeChange(0);
            }
          }
        }
        else{
          if (soundPlaying == true){
            // Mute track in Ableton
            toggleTrack(soundPlaying);
            soundPlaying = false;
          }
          
        }
      }
    }
    distanceStroke = map(distanceToPlayer, 0, width, 10, 1);
  }
  
  void toggleTrack(boolean activated){
      action = 1;
      if (activated){
        //println("Toggled sound off");
        if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, 0);
        if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, 0);
      }
      else{
        //println("Toggled sound on");
        if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, 127);
        if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, 127);
      }    
  }
  
  void volumeChange(float value){
    action = 2;
    if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, int(value));
    if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, int(value));
  }
  
  void getPan(){
    action = 3;
    
    if (shape == "Rectangle"){
      if (channel <= 16) midiBus.sendControllerChange((channel -1), action, 127/2);
      if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, 127/2);
    }
    else{
      // Get the angle of player ear and line to sound
      // If this angle is 90, then we know the player is looking at the sound.
      // If it's more than 90, then the player is looking to the left of the sound
      // If it's less than 90, then the player is looking to the right of the sound.
      float pan = getBalance(playerPosition.x,playerPosition.y, x, y);
      
      // This angle between 0 and 180, is then mapped to a MIDI value for Ableton between 0 and 127.
      // Note that this is flipped, so when looking right of the sound, the audio is panned towards the left ear and vice-versa.
      int panMapped = int(map(pan, 0,180, 127,0));
      // This value should then be sent to Ableton.
      
      if (channel <= 16) midiBus.sendControllerChange((channel -1), action, panMapped);
      if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, panMapped);
  
      // Helper statements meant for debugging. We continuously send the panning to achieve a smooth panning effect.
      // These statements just help us get a general idea if everything is working.
      if (playerClose){
        fill(255,255,255);
        text(name + ", " + panning,x,y);
        text(panMapped,x,y+20);
          
        if (panMapped >= 0 && panMapped < 42 && panning != "Left"){
          if (debugMode) println(name, "is left panned");
          panning = "Left";
        }
        if (panMapped > 42 && panMapped < 85 && panning != "Center"){
          if (debugMode) println(name, "is center panned");
          panning = "Center";
        }
        if (panMapped > 85 && panMapped < 127 && panning != "Right"){
          if (debugMode) println(name, "is right Panned");
          panning = "Right";
        }
      }
    }
  }
  
  void playTrack(boolean activated){
    action = 4;
    if (activated){
        if (name != "Highway Drone 1") println("Stopping ", name);
        if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, 127); // Send a controllerChange
        if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, 127); // Send a controllerChange  
      }
      else{
        if (name != "Highway Drone 1") println("Launching ", name);
        if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, 127); // Send a controllerChange
        if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, 127); // Send a controllerChange  
      }    
  }
  
  // Init static circular sound
  void initSound(int circleDiameter){
    drawCircle(circleDiameter);
    getDistance();
    getPan();  
    playerClose();
  }
  
  // Init static rectangular sound
  void initSound(int rectangleWidth, int rectangleHeight){
    drawRectangle(rectangleWidth,rectangleHeight);
    getDistance();
    getPan();  
    playerClose();
  }
  
  // init drone sound
  void initSound(int circleDiameter, String sound_type){
    type = sound_type;
    drawCircle(circleDiameter);
    getDistance();
    getPan();  
    playerClose();
  }
}
