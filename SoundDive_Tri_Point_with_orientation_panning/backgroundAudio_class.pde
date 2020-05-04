class backgroundAudio {
  float x, y, z; // Coordinates
  String name; // Name
  float distanceToPlayer; // Distance to player, used for volume
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
  backgroundAudio(String soundName, float soundX, float soundY, float soundZ, int soundChannel) {
    name = soundName;
    x = soundX;
    y = soundY;
    z = soundZ;
    channel = soundChannel;
  }
  
  void toggleTrack(boolean activated){
    action = 1;
    if (activated){
      //println("Toggled sound off");
      if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, 0); // Send a controllerChange
      if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, 0);
    }
    else{
      //println("Toggled sound on");
      if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, 127); // Send a controllerChange
      if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, 127);
    }
    
  }
  
  void volumeChange(float value){
    //println("Volume change to ", value);
    action = 2;
    if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, int(value));
    if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, int(value));
  }
  
  // Distance handling
  void getDistance(){
    // Get raw distance
    distanceToPlayer = dist(playerPosition.x, playerPosition.y, z, playerPosition.x, playerPosition.y, playerPosition.z);
    
    // Map distance between 1 and 127 for MIDI control
    // Note this is reversed, so shorter distance equals louder volume
    float distanceMapped = map(distanceToPlayer, 0, 20, 110, 40);
    //if (name == "Background High") println("Volume for bgHigh = ", distanceMapped);
    //if (name == "Background Deep") println("Volume for bgDeep = ", distanceMapped);
    //if (name == "Background High") distanceMapped = map(distanceToPlayer, 0, 20, 40, 1); 
    
    // Send volume change to Ableton
    volumeChange(distanceMapped);
  }
}
