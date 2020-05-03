/* 
  This code is for the AIR LAB orientation and position tracker project.
  More info and resources if found at GitHub: xxx
  Code and project by: Halfdan Hauch Jensen, halj@itu.dk, AIR LAB, IT University of Cph.
  Please make sure to credit when reusing this code... :-)
*/

/*
 For Windows 10, 64bit:
 
 1) Download and install Kinect 1.7 SDK
 2) Download Zadig and replace the drivers for
       Xbox NUI Camera
       Xbox NUI Motor
       Kinect Audio Device
    with LibusbK.
 
 The kinect should now work. If the error "Isochronous transfer error: 1" appears, don't panic, it should work. If screen remains grey, try restarting the sketch a couple of times.

*/
import processing.video.*;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import themidibus.*;

MidiBus midiBus; // Used for sending info and commands to Ableton Live. Handles channels 1-16
int channel = 0;
int number = 0;
float value;

Kinect kinect; // kinect object variable
Movie video; // Video for debugging

Tracker tracker; // tracker for detecting light blobs in video input
Blob [] blobs; // list of blobs

boolean debugMode = false; // Boolean to toggle debug info. Bound to: "p"
boolean kinectEnabled = false; // Boolean for toggling between Kinect and Video tracking. Bound to: "v"
boolean manualMode = true; // Boolean for toggling between Blob based player movement and Manual mouse movement. Bound to: "M"
boolean distanceLines = false; // Boolean for toggling distance lines. Bound to: "l"

boolean diving = false;
boolean rising = false;

PVector playerPosition = new PVector(); // position of player
int currTime, prevTime;
float deltaTime;
 
float prevPlayerPositionX, prevPlayerPositionY;
float playerVelX, playerVelY;
int playerSpeed;
int playerSpeedVolume;
float prevPlayerSpeedVolume = -1;

float frontAngle = 0.0; // front facing angle of player
float prevFrontAngle;
float playerRotation = 0;
float rotation;
boolean playerFoundThisFrame = false; // flag showing if player was tracked in current frame

// Setup window
int w_width = 640;
int w_height = 480;


// Setup sounds
// Format: Name, Color, X, Y, Z, Distance Threshold, Channel (track) and Sub Sound

  // Background
  backgroundAudio backgroundHigh = new backgroundAudio("Background High", 0,0,10, 1);
  backgroundAudio backgroundDeep = new backgroundAudio("Background Deep", 0,0,-10, 2);
  backgroundAudio heartbeat = new backgroundAudio("Heartbeat", 0,0,-10, 12);
  
  // Player
  Sound playerMovement = new Sound("Player Movement", color(255,255,255), playerPosition.x, playerPosition.y, playerPosition.z, 5, 4);
  
  // Elevators
  Sound bubbleElevatorDown = new Sound("Bubble Elevator Down", color(255,255,255), 50, w_height-50, 99, 100, 21);
  Sound bubbleElevatorUp = new Sound("Bubble Elevator Up", color(255,255,255), w_width-50, 50, 99, 100, 22);
  
  // High
  //Sound droneHighway = new Sound("Drone Highway", color(0, 0, 255), 0, 100, 5, 30, 4);
  Sound highwayDrone1 = new Sound("Highway Drone 1", color(0,0,255), 0, 100, 7, 230, 13);
  Sound highwayDrone1_Trail = new Sound("Highway Drone 1_trail", color(255,255,255), highwayDrone1.x-200, highwayDrone1.y, highwayDrone1.z, highwayDrone1.distanceThreshold*2, 14);
  
  Sound highwayDrone2 = new Sound("Highway Drone 2", color(0,255,00), w_width, 150, 7, 230, 15);
  Sound highwayDrone2_Trail = new Sound("Highway Drone 2_trail", color(0,255,0), highwayDrone2.x-50, highwayDrone2.y, highwayDrone2.z, highwayDrone2.distanceThreshold*2, 16);
  
  Sound highwayDrone3 = new Sound("Highway Drone 3", color(255,0,0), w_width/2, 200, 7, 300, 17);
  Sound highwayDrone3_Trail = new Sound("Highway Drone 3_trail", color(255,0,0), highwayDrone3.x-50, highwayDrone3.y, highwayDrone3.z, highwayDrone3.distanceThreshold*2, 18);
  
  Sound highwayDrone4 = new Sound("Highway Drone 4", color(0,255,255), 100, 250, 7, 750, 19);
  Sound highwayDrone4_Trail = new Sound("Highway Drone 4_trail", color(0,255,255), highwayDrone4.x-50, highwayDrone4.y, highwayDrone4.z, highwayDrone4.distanceThreshold*2, 20);
  
  Sound highwayDrone5 = new Sound("Highway Drone 5", color(0,255,255), -500, 140, 7, 30, 21);
  Sound highwayDrone5_Trail = new Sound("Highway Drone 5_trail", color(0,255,255), highwayDrone5.x-50, highwayDrone5.y, highwayDrone5.z, highwayDrone5.distanceThreshold*2, 22);
  
  // Middle
  Sound dataTransfer = new Sound("Data transfer", color(255, 0, 255), 100, 10, 0, 200, 7);
  Sound dataStream = new Sound("Data Stream", color(255,255,255), 100,10,0, 100 ,10);
  Sound dataReceiver = new Sound("White", color(255, 255, 255), 550, 20, 0, 200, 6);
  
  // Deep
  Sound datacenter = new Sound("Data Center", color(0, 255, 0), 440, 380, -5, 400, 3); // change to 440 x 380
  Sound cableDrone = new Sound("Cable Drone", color(255, 255, 0), w_width-(w_width/3)-50, w_height-50, -10, w_width/2, 8);
  Sound cableDroneScan = new Sound("Cable Drone Scan", color(255, 255, 255), cableDrone.x, cableDrone.y, cableDrone.z, w_width/2, 9);
  Sound dataCable = new Sound("Data Cable", color(255,0,0), 0, w_height-30, -10, 60, 5);
  

void setup() {
  size(640, 480);
  if (kinectEnabled == true){
    // setting up the Kinect
    kinect = new Kinect(this);
    kinect.initVideo();
    kinect.enableIR(true);
  }
  
  if (kinectEnabled == false){
    // Setting up debug video
    video = new Movie(this, "IR_test_video_3_dots_v1_640x480.mp4"); // video file in data folder to use for simulation
    video.play();
  }
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
  
  midiBus = new MidiBus(this, -1, "soundDiveMidi"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.

  currTime = prevTime = millis();
  prevPlayerPositionX = prevPlayerPositionY = Float.MAX_VALUE;
  
  cableDrone.startMove(1,0,0);
  dataStream.startMove(3,0,0);
  
  highwayDrone1.startMove(6,0,0);
  
  highwayDrone2.startMove(10,0,0);
  
  highwayDrone3.startMove(5,0,0);
  
  highwayDrone4.startMove(7,0,0);
  
  highwayDrone5.startMove(7,0,0);
}


void draw() {
  video.loadPixels();

  if (kinectEnabled == true){
    image(kinect.getVideoImage(), 0, 0);
    
    // updates the tracker with newest video frame
    tracker.update(kinect.getVideoImage());
  }
  
  if (kinectEnabled == false){
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
  
  
  // ----------------------------------------------------------------
  // ************************ Player handling ************************
 // ----------------------------------------------------------------
  
  
  // Visualize player tracking overlay
  if (playerFoundThisFrame){
    drawOverlay(); // draw visual overlay
  }
  
  /*
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
    //playerSpeed = parseInt(map(playerSpeedUnmapped,0,20000,0,10));
    playerSpeed = parseInt(playerSpeedUnmapped);
  }*/
  
  playerSpeed = parseInt(abs(playerPosition.x-prevPlayerPositionX) + abs(playerPosition.y-prevPlayerPositionY));
  
  prevPlayerPositionX = playerPosition.x;
  prevPlayerPositionY = playerPosition.y;
  
  // Get a rotation of player
  rotation = round(frontAngle);
  
 
// ----------------------------------------------------------------
// ************************ Sound handling ************************
// ----------------------------------------------------------------

  
  // Background sounds
  backgroundHigh.getDistance();
  //heartbeat.getDistance();
  backgroundDeep.getDistance();
  playerSpeedVolume = parseInt(map(playerSpeed,1,30,60,100));
  if (playerSpeed > 0){
    playerMovement.volumeChange(playerSpeedVolume);
    prevPlayerSpeedVolume = playerSpeedVolume;
  }
  if (playerSpeed == 0) {
    if (prevPlayerSpeedVolume == -1) prevPlayerSpeedVolume = playerSpeedVolume;
    prevPlayerSpeedVolume -= 0.75;
    playerMovement.volumeChange(prevPlayerSpeedVolume);
  }
  
  
  bubbleElevatorUp.getDistance();
  bubbleElevatorDown.getDistance();
  
  // Drone Highway
  highwayDrone1.initSound(10, "Drone");
  highwayDrone1.move(-500,highwayDrone1.y,highwayDrone1.z, width+500, highwayDrone1.y, highwayDrone1.z);
  highwayDrone1_Trail.initSound(10, "Drone Trail");
  if (highwayDrone1.speedX > 0) highwayDrone1_Trail.x = highwayDrone1.x - (200 + highwayDrone1.distanceThreshold-50);
  if (highwayDrone1.speedX < 0) highwayDrone1_Trail.x = highwayDrone1.x + (200 + highwayDrone1.distanceThreshold-50);
 
  
 
  highwayDrone2.initSound(10, "Drone");
  highwayDrone2.move(width+5000,highwayDrone2.y,highwayDrone2.z, -5000, highwayDrone2.y, highwayDrone2.z);
  highwayDrone2_Trail.initSound(10, "Drone Trail");
  if (highwayDrone2.speedX > 0) highwayDrone2_Trail.x = highwayDrone2.x - (200 + highwayDrone2.distanceThreshold-50);
  if (highwayDrone2.speedX < 0) highwayDrone2_Trail.x = highwayDrone2.x + (200 + highwayDrone2.distanceThreshold-50);
 
  
  highwayDrone3.initSound(10, "Drone");
  highwayDrone3.move(width+1750,highwayDrone3.y,highwayDrone3.z, -1750, highwayDrone3.y, highwayDrone3.z);
  highwayDrone3_Trail.initSound(10, "Drone Trail");
  if (highwayDrone3.speedX > 0) highwayDrone3_Trail.x = highwayDrone3.x - (200 + highwayDrone3.distanceThreshold-50);
  if (highwayDrone3.speedX < 0) highwayDrone3_Trail.x = highwayDrone3.x + (200 + highwayDrone3.distanceThreshold-50);
  
  
  highwayDrone4.initSound(10, "Drone");
  highwayDrone4.move(-2000,highwayDrone4.y,highwayDrone4.z, width+2000, highwayDrone4.y, highwayDrone4.z);
  highwayDrone4_Trail.initSound(10, "Drone Trail");
  if (highwayDrone4.speedX > 0) highwayDrone4_Trail.x = highwayDrone4.x - (200 + highwayDrone4.distanceThreshold-50);
  if (highwayDrone4.speedX < 0) highwayDrone4_Trail.x = highwayDrone4.x + (200 + highwayDrone4.distanceThreshold-50);
  
  
  /*
  highwayDrone5.initSound(10, "Drone");
  highwayDrone5.move(-5000,highwayDrone5.y,highwayDrone5.z, width+5000, highwayDrone5.y, highwayDrone5.z);
  highwayDrone5_Trail.initSound(10, "Drone Trail");
  highwayDrone5_Trail.x = highwayDrone5.x - 50;
  */
  
  // Cable Drone
  //if (playerPosition.z == cableDrone.z || playerPosition.z > cableDrone.z && cableDrone.z < cableDrone.z + 5 || playerPosition.z < cableDrone.z && playerPosition.z > cableDrone.z - 5){
  
  cableDrone.initSound(40);
  cableDrone.move(0,cableDrone.y, cableDrone.z, width-(width/3), cableDrone.y, cableDrone.z);
  
    // Extra sound for player interaction requires extra logic.
      cableDroneScan.drawCircle(10);
      if (cableDrone.moving == true){
        //cableDroneScan.toggleTrack(true);
        //cableDroneScan.getDistance();
        //cableDroneScan.getPan();
      }
      else{
        //cableDroneScan.toggleTrack(false);
      }
      cableDroneScan.x = cableDrone.x;
      cableDroneScan.y = cableDrone.y;
      cableDroneScan.z = cableDrone.z;

  // Data Cable
  dataCable.initSound(width-(width/3), 20);
  
  // Datacenter
  datacenter.initSound(50);

  // Data Transfer
  dataTransfer.initSound(10);
  
  dataStream.initSound(10);
  dataStream.move(dataTransfer.x,dataTransfer.y, dataTransfer.z, dataReceiver.x,dataReceiver.y, dataReceiver.z);
  
  // White sound
  //dataReceiver.initSound("Circle",10,0);
  
  
  // Dive-area
  bubbleElevatorUp.drawCircle(50);
  
  if (dist(playerPosition.x,playerPosition.y,bubbleElevatorUp.x,bubbleElevatorUp.y) <= 50 && playerPosition.z != -10){
    diving = true;
  }
  else{
    diving = false;
  }
  
  if (diving == true){
    if (playerPosition.z > -10){
      playerPosition.z -= 0.01;
    }
  }
  
  // Rise-area
  bubbleElevatorDown.drawCircle(50);
  
  if (dist(playerPosition.x,playerPosition.y,bubbleElevatorDown.x,bubbleElevatorDown.y) <= 50 && playerPosition.z != 10){
    rising = true;
  }
  else{
    rising = false;
  }
  
  if (rising == true){
    if (playerPosition.z < 10){
      playerPosition.z += 0.025;
    }
  }
  
  prevFrontAngle = frontAngle;
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
    kinectEnabled = !kinectEnabled;
    println("kinectEnabled is ", kinectEnabled);
  }
  
  if (key == 'l'){
    distanceLines = !distanceLines;
    println("distanceLines is ", distanceLines);
  }
  
  if (key == 'm'){
    manualMode = !manualMode;
    println("Manual control is ", manualMode);
  }
  
  if (key == CODED && manualMode == true){
    if (keyCode == SHIFT){
      if (playerPosition.z > -10){
        playerPosition.z = playerPosition.z - 1;
      }
    }
  }
  if (key == ' ' && manualMode == true){
    if (playerPosition.z < 10){
      playerPosition.z = playerPosition.z + 1;
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
