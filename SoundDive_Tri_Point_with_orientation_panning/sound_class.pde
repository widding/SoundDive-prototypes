class Sound {
  float x, y, z; // Coordinates
  String name; // Name
  color debug_color; // Color shown on display

  float distanceToPlayer; // Distance to player, used for volume
  float distanceStroke; // Strokewidth to show distance
  float distanceThreshold = 0; // Distance threshold, used for when to trigger sound
  boolean soundPlaying = false; // Check if player has triggered sound
  boolean positionFound = false; // Check if we've located the sound (Cardinal direction in relation to sketch center);
  
  String panning = "Center"; // Helper debug value used to check whether our panning logic works.
  
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
      
    The value is usually a number between 1 and 127, and tells Ableton what to do.
    
    Examples:
      Channel 1, Action 2 and Value 127 means: turn track 1 up to max volume.
      Channel 3, Action 1 and Value 0 means: turn track 3 off.
      Channel 2, action 3 and Value 60 means: pan track 2 in between L(1) and R(127).
  */
  
  // Constructor
  Sound(String soundName, color soundColor, float soundX, float soundY, float soundZ, float threshold, int soundChannel) {
    name = soundName;
    debug_color = soundColor;
    x = soundX;
    y = soundY;
    z = soundZ;
    if (distanceThreshold != 0){
      distanceThreshold = threshold;
    }
    else{
      distanceThreshold = 100;
    }
    channel = soundChannel;
  }

  // Draw color
  void show(int colorDiameter){
    noStroke();
    fill(debug_color);
    circle(x,y,colorDiameter);
  }

  // Distance handling
  void getDistance(){
    // Get raw distance
    distanceToPlayer = dist(x,y,playerPosition.x, playerPosition.y);
    distanceStroke = map(distanceToPlayer, 0, width, 10, 1); 
    
    // If distance is within threshold for sound, continue on. If not, mute the sound.
    if (distanceToPlayer <= distanceThreshold){
      
      // Map distance between 1 and 127 for MIDI control
      // Note this is reversed, so shorter distance equals louder volume
      float distanceMapped = map(distanceToPlayer, 0, 300, 127, 1); 
      
      // Activate track in Ableton if it's not already enabled
      if (soundPlaying == false){
        //println("Player is within threshold");
        toggleTrack(soundPlaying);
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
        toggleTrack(soundPlaying);
        soundPlaying = false;
      }
      
    }
  }
  
  void toggleTrack(boolean activated){
    action = 1;
    if (activated){
      //println("Toggled sound off");
      myBus.sendControllerChange((channel - 1), action, 0); // Send a controllerChange
    }
    else{
      //println("Toggled sound on");
      myBus.sendControllerChange((channel - 1), action, 127); // Send a controllerChange
    }
    
  }
  
  void volumeChange(float value){
    println("Volume for channel", channel, "change to ", value);
    action = 2;
    myBus.sendControllerChange((channel - 1), action, int(value));
  }
  
  void getPan(){
    // Get the angle of player ear and line to sound
    // If this angle is 90, then we know the player is looking at the sound.
    // If it's more than 90, then the player is looking to the left of the sound
    // If it's less than 90, then the player is looking to the right of the sound.
    float pan = getBalance(playerPosition.x,playerPosition.y, x, y);
    
    // This angle between 0 and 180, is then mapped to a MIDI value for Ableton between 0 and 127.
    // Note that this is flipped, so when looking right of the sound, the audio is panned towards the left ear and vice-versa.
    int panMapped = int(map(pan, 0,180, 127,0));
    // This value should then be sent to Ableton.
    
    action = 3;
    myBus.sendControllerChange((channel -1), action, panMapped);

    // Helper statements meant for debugging. We continuously send the panning to achieve a smooth panning effect.
    // These statements just help us get a general idea if everything is working.
    fill(255,255,255);
    text(panning,x,y);
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
