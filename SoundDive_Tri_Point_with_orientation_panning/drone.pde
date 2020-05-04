class Drone {
  String name; // Name
  int trackLength; // Length of track in seconds

  boolean soundPlaying = false; // Check if player has triggered sound
  
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
  Drone(String soundName, int track_length, int soundChannel) {
    name = soundName;
    trackLength = track_length;
    channel = soundChannel;
  }
  
  void encounter(boolean encountered){    
    action = 4;
    if (encountered){
        println("Player encountered ", name);
        if (channel <= 16) midiBus.sendControllerChange((channel - 1), action, 127); // Send a controllerChange
        if (channel > 16)  midiBus.sendControllerChange((channel - 17), action+4, 127); // Send a controllerChange
      }
  }
}
