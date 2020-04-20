/* 
  This code is for the AIR LAB orientation and position tracker project.
  More info and resources if found at GitHub: xxx
  Code and project by: Halfdan Hauch Jensen, halj@itu.dk, AIR LAB, IT University of Cph.
  Please make sure to credit when reusing this code... :-)
*/
import processing.video.*;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import themidibus.*;

MidiBus myBus; // Used for sending info and commands to Ableton Live
int channel = 0;
int number = 0;
float value;

Kinect kinect; // kinect object variable
Movie video; // Video for debugging

Tracker tracker; // tracker for detecting light blobs in video input
Blob [] blobs; // list of blobs

boolean debugMode = false; // Boolean to toggle debug info. Bound to: "p"
boolean videoMode = false; // Boolean for toggling between Kinect and Video tracking. Bound to: "v"
boolean manualMode = true; // Boolean for toggling between Blob based player movement and Manual mouse movement. Bound to: "M"
boolean distanceLines = true; // Boolean for toggling distance lines. Bound to: "l"

PVector playerPosition = new PVector(); // position of player
int currTime, prevTime;
float deltaTime;
 
float prevPlayerPositionX, prevPlayerPositionY;
float playerVelX, playerVelY, playerSpeed;

float frontAngle = 0.0; // front facing angle of player
float rotation;
boolean playerFoundThisFrame = false; // flag showing if player was tracked in current frame

// Setup sounds
// Format: Name, Color, X, Y, Z, Distance Threshold and Channel (track)
Sound backgroundHigh = new Sound("Background High", color(255,255,255), 0,0,10, 0, 1);
Sound backgroundDeep = new Sound("Background Deep", color(255,255,255), 0,0,-10, 0, 2);

// Format: Name, Color, X, Y, Z, Distance Threshold and Channel (track)
Sound soundGreen = new Sound("Green", color(0, 255, 0), 150, 150, 0, 100, 3);
Sound soundBlue = new Sound("Blue", color(0, 0, 255), 300, 300, 0, 200, 4);
Sound soundRed = new Sound("Red", color(255, 0, 0), 400, 150, 0, 200, 5);

Sound soundPurple = new Sound("Purple", color(255, 0, 255), 100, 10, 0, 200, 7);
Sound soundWhite = new Sound("White", color(255, 255, 255), 550, 20, 0, 200, 6);

Sound soundYellow = new Sound("Yellow", color(255, 255, 0), 550, 400, 0, 100, 8);
  int soundYellowSpeedX = 2;
  int soundYellowSpeedY = 0;
void setup() {
  println("Starting up soundDive");

  size(640, 480);
  
  // setting up the Kinect
  kinect = new Kinect(this);
  kinect.initVideo();
  kinect.enableIR(true);
  
  // Setting up debug video
  video = new Movie(this, "IR_test_video_3_dots_v1_640x480.mp4"); // video file in data folder to use for simulation
  video.play();
  
  tracker = new Tracker(); // Creating the tracker object
  
  // TRACKER SETTINGS
  tracker.brightThreshold = 200;      // min brightness for the pixels that can belong to a blob
  tracker.minNrOfPixels = 5;          // min nr of pixels belonging to the blob
  //tracker.maxNrOfPixels = 500;      // max nr of pixels belonging to the blob
  tracker.minArea = 4;                // min area (w*h) of bounding box
  //tracker.maxArea = 1000;           // max area (w*h) of bounding box
  tracker.minWidth = 2;               // min width for bounding box
  //tracker.maxWidth = 50;            // min width for bounding box
  tracker.minHeight = 2;              // min height for bounding box
  //tracker.maxHeight = 50;           // max height for bounding box
  //tracker.pixelToAreaRatio = 0.5;   // ratio of pixels in the bounding box that must belon to the blob (1.0 means all pixels) 
  //tracker.widthToHeightRatio = 0.4; // ratio of how squared the bounding box must be. 0.0 is perfect square
  
  myBus = new MidiBus(this, -1, "soundDiveMidi"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.

  currTime = prevTime = millis();
  prevPlayerPositionX = prevPlayerPositionY = Float.MAX_VALUE;
}


void draw() {
  video.loadPixels();

  if (videoMode == false){
    image(kinect.getVideoImage(), 0, 0);
    
    // updates the tracker with newest video frame
    tracker.update(kinect.getVideoImage());
  }
  
  if (videoMode == true){
    image(video, 0, 0);
    
    if (video.time() > video.duration() -2){ 
      video.jump(0);
    }
    
    tracker.update(video); 
    
    if (playerPosition.z < -5){
    background(0,0,0);
    }
    if (playerPosition.z >= -5 && playerPosition.z <= 5){
      background(51,51,51);
    }
    if (playerPosition.z > 5){
      background(102, 102, 102);
    }
  }
  
  //println("Video time", video.time(), "/", video.duration()); // prints the video file time info

  
  // extract a blob list from the tracker class
  blobs = tracker.getBlobs();
  
  // detects a player and sets the player found flag
  if (manualMode == false){
    playerFoundThisFrame = findPlayer(); 
  }
  
  if (manualMode == true){
    drawOverlay(); // draw visual overlay
    playerPosition.x = mouseX;
    playerPosition.y = mouseY;
  }
 
  // visualizes all blobs from the tracker object
  tracker.show(); 
  
  // Visualize player tracking overlay
  if (playerFoundThisFrame){
    drawOverlay(); // draw visual overlay
  }
  
  // Get player speed
  // get the current time
  currTime = millis();
  // calculate the elapsed time in seconds
  deltaTime = (currTime - prevTime)/1000.0;
  // remember current time for the next frame
  prevTime = currTime;
 
  // Calculate velocity in X and Y directions (pixels / second)
  if(prevPlayerPositionX != Float.MAX_VALUE){
    playerVelX = (playerPosition.y - prevPlayerPositionX) / deltaTime;
    playerVelY = (playerPosition.y - prevPlayerPositionY) / deltaTime;
    float playerSpeedUnmapped = sqrt(playerVelX*playerVelX + playerVelY*playerVelY);
    playerSpeed = parseInt(map(playerSpeedUnmapped,0,20000,0,10));
  }
  prevPlayerPositionX = playerPosition.x;
  prevPlayerPositionY = playerPosition.y;

  /*
    Sound handling
  */
  
  // Center dot
  noStroke();
  fill(255,255,255);
  ellipse(width/2,height/2,10,10);
  
  // Get a rotation of player
  rotation = round(frontAngle);
  
  // Background sounds
  backgroundHigh.getDistance();
  backgroundDeep.getDistance();
  
  // Yellow sound
  if (playerPosition.z == soundYellow.z || playerPosition.z > soundYellow.z && playerPosition.z < soundYellow.z + 3 || playerPosition.z < soundYellow.z && playerPosition.z > soundYellow.z - 3){
    soundYellow.show(40);
    soundYellow.getDistance();
    soundYellow.getPan();
  
    
    soundYellow.x += soundYellowSpeedX;
    if (soundYellow.x == width){
      soundYellowSpeedX = -soundYellowSpeedX;
    }
    if (soundYellow.x < 0){
      soundYellowSpeedX = -soundYellowSpeedX;
    }
    if (distanceLines){
      strokeWeight(abs(soundYellow.distanceStroke));
      stroke(255,255,0);
      line(soundYellow.x,soundYellow.y,playerPosition.x,playerPosition.y);
    }
  }
  
  
  // Green sound
  soundGreen.show(50);
  soundGreen.getDistance();
  soundGreen.getPan();
  if (distanceLines){
    strokeWeight(abs(soundGreen.distanceStroke));
    stroke(0,255,0);
    line(soundGreen.x,soundGreen.y,playerPosition.x,playerPosition.y);
  }
  
  // Blue Sound
  soundBlue.show(30);
  soundBlue.getDistance();
  soundBlue.getPan();
  if (distanceLines){
    strokeWeight(abs(soundBlue.distanceStroke));
    stroke(0,0,255);
    line(soundBlue.x,soundBlue.y,playerPosition.x,playerPosition.y);
  }
  
  // Red Sound
  soundRed.show(20);
  soundRed.getDistance();
  if (debugMode){ // Hands position of Red sound over to mouse input
    soundRed.x = mouseX;
    soundRed.y = mouseY;
    soundRed.getPan();
  }
  
  else{
    soundRed.getPan();
  }
  
  if (distanceLines){
    strokeWeight(abs(soundRed.distanceStroke));
    stroke(255,0,0);
    line(soundRed.x,soundRed.y,playerPosition.x,playerPosition.y);
  }
  
  // Purple sound
  soundPurple.show(10);
  soundPurple.getDistance();
  soundPurple.getPan();
  
  // White sound
  soundWhite.show(10);
  soundWhite.getDistance();
  soundWhite.getPan();
}




// ----------------------------------------------------------------
// ************************ HELPER METHODS ************************
// ----------------------------------------------------------------


// --- method that detect a player in the blob list data, updates global variables and returns boolean ---
boolean findPlayer(){
  
  // create return variable
  boolean playerFound = false; 
  
  // check that we have exactly three blobs
  if (blobs.length == 3){
    
    // traverse the three blob points
    for (int i = 0; i < blobs.length; i++){
      
      // get angle between current blob and the two other
      float angleBetween = getAngleBetween(blobs[i].center.x, blobs[i].center.y, blobs[(i+1)%3].center.x, blobs[(i+1)%3].center.y, blobs[(i+2)%3].center.x, blobs[(i+2)%3].center.y);
      
      // check if the current blob is the back point
      if (angleBetween > 100) {
        playerFound = true; // flag player found
        playerPosition = blobs[i].center; // update global variable with player position 

        
        float rotationA = getRotation(blobs[i].center.x, blobs[i].center.y, blobs[(i+1)%3].center.x, blobs[(i+1)%3].center.y); // rotation of one of the side points
        float rotationB = getRotation(blobs[i].center.x, blobs[i].center.y, blobs[(i+2)%3].center.x, blobs[(i+2)%3].center.y); // rotation of the other side point
        
        // calculate and set the rotation angle
        if (abs(rotationA-rotationB) > 150){ // counter clockwise rotation
          frontAngle = min(rotationA, rotationB) - 120/2;
          if (frontAngle < 0) frontAngle = 360+frontAngle; 
        }
        else frontAngle = min(rotationA, rotationB) + 120/2; // clock wise rotation
        
      }
    }
  }
  return playerFound;
}


// --- methosd that draws visual overlay of tracking info ---
void drawOverlay(){
    // draw ellipse on top of player position blob / player position
    fill(255);
    noStroke();
    circle(playerPosition.x, playerPosition.y, 15);
        
    // draw direction line (frontAngle)
    pushMatrix();
    translate(playerPosition.x, playerPosition.y);
    rotate(radians(frontAngle));
    stroke(#F70AF7);
    line(0,0,0,-30);
    popMatrix();
    
    // draw angle and position texts
    textSize(15);
    text("Debug mode: " + debugMode, 10, 30);
    text("Angle: " + round(frontAngle) + "°", 10, 55);
    text("Position", 10, 80);
    text("X: " + playerPosition.x, 30, 100);
    text("Y: " + playerPosition.y, 30, 125);
    text("Z: " + playerPosition.z, 30, 150);
    text("Speed: " + playerSpeed, 10, 175);
}


// --- method that calculates rotation of one point around another ---
float getRotation(float x1, float y1, float x2, float y2){
  
  PVector a = new PVector(x1, y1);   // point a
  PVector b = new PVector(x2, y2);   // point b
  PVector r = new PVector(0, -100);  // reference point
 
  b.sub(a);             // move point b
  a.sub(a);             // move point a
  
  // calculate rotation
  float angle = degrees(PVector.angleBetween(r,b));
  if (b.x < 0){ // turn result around if b is on the left side of a
    angle = 360 - angle;  
  }
  return angle; // return angle
}


// --- method that calculates the angle from point (a_x, a_x) and to the two other points (b_x, b_y) & (c_x, c_y) ---
float getAngleBetween(float a_x, float a_y, float b_x, float b_y, float c_x, float c_y){
  
  PVector a = new PVector(a_x, a_y);   // point a
  PVector b = new PVector(b_x, b_y);   // point b
  PVector c = new PVector(c_x, c_y);   // point c
 
  c.sub(a);             // move point c
  b.sub(a);             // move point b
  a.sub(a);             // move point a to zero
    
  // calculate angle
  float angle = degrees(PVector.angleBetween(b,c));
  
  return angle; // return angle
}

// Method that gets balance
float getBalance(float x1, float y1, float x2, float y2){
  
  PVector a = new PVector(x1, y1);   // point a
  PVector b = new PVector(x2, y2);   // point b
  PVector r = new PVector(0, -100);  // reference point
  r.rotate(radians(frontAngle+90));
 
  b.sub(a);             // move point b
  a.sub(a);             // move point a
  
  // calculate rotation
  float angle = degrees(PVector.angleBetween(r,b));
  return angle; // return angle
}

void keyPressed() {
  if (key == 'p') {
    debugMode = !debugMode;
    println("Debug mode is ", debugMode);
  }
  
  if (key == 'v'){
    videoMode = !videoMode;
    println("Video mode is ", videoMode);
  }
  
  if (key == 'l'){
    distanceLines = !distanceLines;
    println("distanceLines is ", distanceLines);
  }
  
  if (key == 'm'){
    manualMode = !manualMode;
    println("Manual control is ", videoMode);
  }
  
  if (key == CODED && manualMode == true){
    if (keyCode == SHIFT){
      if (playerPosition.z > -10){
        println("Player diving");
        playerPosition.z = playerPosition.z - 1;
      }
      else{
        println("Player has reached the seafloor");
      }
    }
  }
  if (key == ' ' && manualMode == true){
    if (playerPosition.z < 10){
      println("Player moving up");
      playerPosition.z = playerPosition.z + 1;
    }
    else{
      println("Player has reached the surface");
    }
  }
  
  if (key == 'q' && manualMode == true){
    if (frontAngle == 360){
      frontAngle = 0;
    }
    if (frontAngle == -1){
      frontAngle = 360;
    }
    
     frontAngle -= 1;
    
  }
  
  if (key == 'e' && manualMode == true){
    if (frontAngle == 360){
      frontAngle = 0;
    }
    if (frontAngle == -1){
      frontAngle = 360;
    }
     frontAngle += 1;
    
  }
}
