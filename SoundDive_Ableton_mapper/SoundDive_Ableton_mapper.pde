import themidibus.*;

MidiBus myBus; // Used for sending info and commands to Ableton Live

int channel; // Channel for the MIDI note
int action; // Action for the MIDI note.
int value; // Value for the MIDI note.
boolean playing = false;
  
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

void setup() {

  size(640, 480);
  myBus = new MidiBus(this, -1, "soundDiveMidi"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.

}

void draw(){}

void keyPressed(){
  if (key == '1') {
    println("Maping action 1");
    channel = 12;
    action = 1;
    if (playing == false){
      value = 127;
    }
    if (playing == true){
      value = 0;
    }
    
    playing = !playing;
    
    println("Mapped channe l", channel);
    myBus.sendControllerChange((channel - 1), action, value); // Send a controllerChange
  }
  
  if (key == '2') {
    channel = 12;
    action = 2;
    if (playing == false){
      value = 127;
    }
    if (playing == true){
      value = 0;
    }
    
    playing = !playing;
    
    println("Maping action: ", action);
    println("Mapped channe: ", channel);
    myBus.sendControllerChange((channel - 1), action, value); // Send a controllerChange
  }
  
  if (key == '3') {
    channel = 12;
    action = 3;
    if (playing == false){
      value = 127;
    }
    if (playing == true){
      value = 0;
    }
    
    playing = !playing;
    
    println("Maping action: ", action);
    println("Mapped channe: ", channel);
    myBus.sendControllerChange((channel - 1), action, value); // Send a controllerChange
  }
  
  if (key == '4') {
    channel = 8;
    action = 4;
    if (playing == false){
      value = 127;
    }
    if (playing == true){
      value = 0;
    }
    
    playing = !playing;
    
    println("Maping action: ", action);
    println("Mapped channe: ", channel);
    myBus.sendControllerChange((channel - 1), action, value); // Send a controllerChange
  }
  
  if (key == '5') {
    channel = 8;
    action = 5;
    if (playing == false){
      value = 127;
    }
    if (playing == true){
      value = 0;
    }
    
    playing = !playing;
    
    println("Maping action: ", action);
    println("Mapped channe: ", channel);
    myBus.sendControllerChange((channel - 1), action, value); // Send a controllerChange
  }
}
