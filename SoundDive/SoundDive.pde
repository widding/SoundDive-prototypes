//Program made by Victor Permild (vbpe@itu.dk) for AIR Lab Workshop #1: Interactive Spaces with Kinect and Processing.

//Kinect setup. No need to change anything here :)
import oscP5.*;
import netP5.*;
import processing.sound.*;
SoundFile ambiance;
SoundFile bass;
SoundFile sonar;
SoundFile animal;
SoundFile industry;
OscP5 oscP5;
NetAddress myRemoteLocation;

SinOsc sine;

PVector mx, pmx;

//Define global variables below:
float controllerX, controllerY, previousX, previousY;
float size;

//Set the interval between each time the sketch wipes itself clean. Default is 15 seconds.
float cleanTimerInSeconds = 0.1;

// Coords for player in int
int[] playerCoords = { 0, 0 };
float directionX, directionY;

// Coords for sounds
float[] redCoords = { 400, 150 };
float redXSpeed = 1;
float redYSpeed = 1;
float redOrbitVal;
float redOrbitSpeed = 0.01;
float[] greenCoords = { 200, 150 };
float[] blueCoords = { 600, 450 };
float distanceToRed, distanceToGreen, distanceToBlue;

String currDirection;
boolean flipSound;

void setup() {
  //Choose if you want to use size() or fullscreen(). 
  //Comment the counterpart out, as these two function cannot run at the same time.
  size(800, 500);
  //fullScreen();

  //Kinect setup
  startKinectOSC();

  //Uncomment function below to hide the mouse pointer
  //noCursor();
  sonar = new SoundFile(this, "sonar.mp3");
  //sonar.loop();
  sonar.amp(0.01);
  animal = new SoundFile(this, "animal.mp3");
  //animal.loop();
  animal.amp(0.01);
  industry = new SoundFile(this, "industry.mp3");
  //industry.loop();
  industry.amp(0.01);
  ambiance = new SoundFile(this, "UnderWaterLoop.wav");
  //ambiance.loop();
  //sine = new SinOsc(this);
  //sine.play();
  
  //Set the background to black
  background(bgColor);
}

void draw() {
  //Create a blurring background effect
  noStroke();
  fill(bgColor, 1);
  rect(0, 0, width, height);

  //Shows the actual position of the controller if toggled on (toggle with key '5')
  if (showTarget) {
    fill(0, 0, 255);
    ellipse(controllerX, controllerY, minSize*4, minSize*4);
    text("AIR LAB", controllerX,controllerY);
  }
  
  playerCoords[0] = int(easingX);
  playerCoords[1] = int(easingY);
  
  distanceToRed = dist(redCoords[0],redCoords[1],playerCoords[0],playerCoords[1]);
  distanceToGreen = dist(greenCoords[0],greenCoords[1],playerCoords[0],playerCoords[1]);
  distanceToBlue = dist(blueCoords[0],blueCoords[1],playerCoords[0],playerCoords[1]);
  
    if (controllerX > previousX) {
    if (currDirection != "right"){
      currDirection = "right";
      directionX = easingX + 30;
      directionY = 0;
      //println(currDirection);
    }
  }
  else if (controllerX < previousX) {
    if (currDirection != "left"){
      currDirection = "left";
      directionX = easingX - 30;
      directionY = 0;
      //println(currDirection);
    }
  }
  else if (controllerY > previousY) {
    if (currDirection != "down"){
      currDirection = "down";
      directionX = 0;
      directionY = easingY - 30;
      flipSound = true;
      //println(currDirection);
      
    }
  }
  else if (controllerY < previousY) {
    if (currDirection != "up"){
      flipSound = false;
      directionX = 0;
      directionY = easingY + 30;
      currDirection = "up";
      //println(currDirection);
    }
  }
  
  ////// Sound playback
  getCardinalPlacement(redCoords, "red");
  
  float redPan = map((playerCoords[0] - redCoords[0]), 100,-100,1,-1);
  if (industry.isPlaying()){
    industry.pan(redPan);
    if (distanceToRed < 100){
      float redVolume = map(distanceToRed / 100,0,10,1,0);
      industry.amp(redVolume);
    }
    else{
      industry.amp(0.01);
    }
  }
  
  redCoords[0] = sin(redOrbitVal);
  redCoords[1] = cos(redOrbitVal);
  
  redCoords[0] *= 80;
  redCoords[1] *= 80;
  
   redCoords[0] += 450;
   redCoords[1] += 150;
  
  redOrbitVal += redOrbitSpeed;
  
  /*redCoords[0] += redXSpeed;
  redCoords[1] += redYSpeed;
  
  if (redCoords[0] < 0 || redCoords[0] > width) {
    redXSpeed *= -1;
  }

  if (redCoords[1] < 0  || redCoords[1] > height) {
    redYSpeed *= -1;
  }*/
  
  // Check where the player is based on their X and Y coordinates in relation to the sound
  // If the player is facing NORTH:
    // If X > sound.x then the player is to the right.
    // If X < sound.x then the player is to the left.
    
  // Number values for Cardinal Directions relative to baseline
  // 0 == N
  // 1 == NE
  // 2 == E
  // 3 == SE
  // 4 == S
  // 5 == SW
  // 6 == W
  // 7 == NW
  // 8 == C
 
  /*
  // Is the player north of the sound?
  if (playerCoords[0] == greenCoords[0] && playerCoords[1] > greenCoords[1]){
    println("Player is north");
  }
  
  // Is the player south of the sound?
  if (playerCoords[0] == greenCoords[0] && playerCoords[1] < greenCoords[1]){
    println("Player is south");
  }
 */
   
  //getCardinalPlacement(greenCoords, "Green");
  
  float greenPan = map((playerCoords[0] - greenCoords[0]), 100,-100,1,-1);
  //println(greenPan);
  if (animal.isPlaying()){
    animal.pan(greenPan);
    if (distanceToGreen < 500){
      float greenVolume = map(distanceToGreen / 100,0,1,1,0);
      animal.amp(greenVolume);
    }
    else{
      animal.amp(0.01);
    }
  }
  
  
  float bluePan = map((playerCoords[0] - blueCoords[0]), 100,-100,1,-1);
  
  if (sonar.isPlaying()){
    sonar.pan(bluePan);
    if (distanceToBlue < 100){
      float blueVolume = map(distanceToBlue / 100,0,10,1,0);
      sonar.amp(blueVolume);
    }
  }

  // Player
  fill(255, 0, 0);
  noStroke();
  ellipse(easingX, easingY, size, size);
  
  // Player sphere of influence
  stroke(255,255,255);
  noFill();
  line(easingX,easingY, previousX,previousY);
  ellipse(easingX, easingY, 100, 100);
  
  // Green sound
  noStroke();
  fill(0, 255, 0);
  ellipse(greenCoords[0],greenCoords[1],50,50);
  
  // Red Sound
  noStroke();
  fill(255, 0, 0);
  ellipse(redCoords[0],redCoords[1],80,80);
  
  // Blue Sound
  noStroke();
  fill(0, 0, 255);
  ellipse(blueCoords[0],blueCoords[1],120,120); 

  //Keep this function at the bottom of draw()
  runFunctions();
  
  pushMatrix();
  size(800, 500);
  translate(width/2, height/2);
  fill(255, 255, 255);
  ellipse(0,0,10,10);
  PVector v1 = new PVector(0, height/2);
  //println(mouseX-150, mouseY-150);
  PVector v2 = new PVector(mouseX-400, mouseY-250); 
  float a = PVector.angleBetween(v1, v2);
  if (v2.x < v1.x){
    //println(180 + 180-degrees(a));
  }
  //else println(degrees(a));  // Prints "10.304827"
  popMatrix();
  
}

void getCardinalPlacement(float soundCoords[], String sound){
  // Where is the player in relation to the sound (North, South or in the center) 
  if (playerCoords[1] < soundCoords[1]){ // Is the player north of the sound?
    println("Player is in north of ", sound);
  }
  
  else if(playerCoords[1] == soundCoords[1]){ // Is the player in center?
   println("Player is in center of ", sound);
  }
  
  else{ // The player must be south
    println("Player is south of ", sound);
  }//End of north\south check
  
  
  // Where is the player in relation to the sound (East, west or in the center)
  if(playerCoords[0] > soundCoords[0]){ //Is the player east of the sound?
     println("Player is east of ", sound);
   } 
   else if(playerCoords[0] == soundCoords[0]){ //is the player in center?
     println("Player is in center of ", sound);
   }
   else{ //player must be west
     println("Player is west of ", sound);
   } // End of east\west check
}
