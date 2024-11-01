// --- BEGIN SHIM; REMOVE TO RUN ON DESKTOP ---
// (jump to line 62 for project code)

void circle(float x, float y, float extent) {
  ellipse(x, y, extent, extent);
}

void square(float x, float y, float extent) {
  rect(x, y, extent, extent)
}

void clear() {
  background(color(255, 255, 255));
}

void delay(int length) {
  long blockTill = Date.now() + length;
  while (Date.now() <= blockTill) {}
}

String __errBuff = "";
String __outBuff = "";

var System = {};
System.out = {};
System.err = {};

System.err.print = function (chars) {
  __errBuff += chars;
  String[] newlines = __errBuff.split("\n");
  if (newlines.length > 0) {
    String[] linesToPrint = newlines.slice(0, newlines.length - 1);
    linesToPrint.forEach(function (line) {
      console.error(line);
    })
    __errBuff = newlines[newlines.length - 1];
  }
};

System.currentTimeMillis = function () { return Date.now(); }

System.err.println = function (chars) {
  System.err.print(chars + "\n");
};

System.out.print = function (chars) {
  __outBuff += chars;
  String[] newlines = __outBuff.split("\n");
  if (newlines.length > 0) {
    String[] linesToPrint = newlines.slice(0, newlines.length - 1);
    linesToPrint.forEach(function (line) {
      console.log(line);
    })
    __outBuff = newlines[newlines.length - 1];
  }
};

System.out.println = function (chars) {
  System.out.print(chars + "\n");
};
// --- END SHIM; REMOVE TO RUN ON DEKTOP ---
import java.util.*;

ArrayList<Particle> particles;
ArrayList<AmbientStar> ambientStars = new ArrayList();

color framebufferColor = color(5);
boolean paused = false;

long lastFrameTime = 0;

final int NUM_AMBIENT_STARS = 1_000;
final int NUM_PARTICLES = 100;
final int MAX_CULL_DEV = 256;
final int MAX_PARTICLES = 500;


void setup() {
  // size(512, 512, P3D);
  size(512, 512);
  noStroke();

  for (int i = 0; i < NUM_AMBIENT_STARS; i++) {
    ambientStars.add(new AmbientStar(random(width + MAX_CULL_DEV) * (Math.random() > 0.5 ? 1 : -1), random(height + MAX_CULL_DEV) * (Math.random() > 0.5 ? 1 : -1)));
  }
  particles = new ArrayList();
  particles.add(new OddballParticle(width / 2, width / 2, 1, 0));
  background(framebufferColor);
  lastFrameTime = System.currentTimeMillis();
}

void keyPressed() {
  if (key == ' ') {
    paused = !paused;
  }
}

void draw() {
  float fps = 1000.0f / (System.currentTimeMillis() - lastFrameTime);
  document.title = ("Deep Space Exploration | FPS: " + fps.toFixed(2));
  lastFrameTime = System.currentTimeMillis();
  pushMatrix();
  translate((mouseX - width / 2) * -0.05, (mouseY - height / 2) * -0.05);
  for (AmbientStar star : ambientStars) {
    star.tick();
    star.draw();
  }
  popMatrix();

  translate((mouseX - width / 2) * -0.3, (mouseY - height / 2) * -0.3);

  loadPixels();
  doMotionBlur();
  ArrayList<Particle> pendingCull = new ArrayList();

  // bulk loading/writing of framebuffer
  // is a cpu shader optimal? no. is it optimal to read from the gpu, shade it on the cpu, and write it back? no.
  // but yes
  
  ArrayList<Particle> current = particles;
  particles = particles.clone();
  for (Particle parc : current) {
    if (parc.x > width + MAX_CULL_DEV || parc.x < -MAX_CULL_DEV || parc.y > height + MAX_CULL_DEV || parc.y < -MAX_CULL_DEV) {
      pendingCull.add(parc);
    } else {
      if (!paused) parc.tick();
      parc.shade();
    }
  }
  updatePixels();

  for (Particle parc : pendingCull) particles.remove(parc);

  for (Particle parc : particles) parc.draw();

  // int pending = NUM_PARTICLES - particles.size();
  // if (pending > 0) {
  //   for (int i = 0; i < pending; i++) {
  //     // particles.add(randomParticle(this));
  //   }
  // }
}

void doMotionBlur() {
  for (int i = 0; i < pixels.length; i++) {
    color pxClr = pixels[i];
    pixels[i] = lerpColor(pxClr, framebufferColor, 0.3);
  }
}

Particle randomParticle(PApplet app) {
  double x = app.random((float) app.width);
  double y = app.random((float) app.height);
  double speed = app.random(1, 1);
  double angle = app.random(TWO_PI);
  color clr = app.color(app.random(128) + 127, app.random(128) + 127, app.random(128) + 127);
  return new Particle(x, y, speed, angle, clr);
}

class Particle {
  double x, y, speed, angle;
  double fric = 0.9999;
  color clr;
  
  Particle(double x, double y, double speed, double angle, color clr) {
    this.x = x;
    this.y = y;
    this.speed = speed;
    this.angle = angle;
    this.clr = clr;
  }  

  Particle(double x, double y, double speed, double angle, color clr, double fric) {
    this.x = x;
    this.y = y;
    this.speed = speed;
    this.angle = angle;
    this.clr = clr;
    this.fric = fric;
  }

  void tick() {
    double speed = this.speed;
    if (mousePressed) {
      speed = speed * 2;
    }

    x += speed * Math.cos(angle);
    y += speed * Math.sin(angle);
    speed *= fric;
  }

  void draw() {
    pushMatrix();
    translate((float) x, (float) y);
    fill(clr);
    circle(0, 0, 10);
    popMatrix();
  }

  void shade() {
    this.shade(50, color(128));
  }

  void shade(int radius, color clr) {
      final float MAGNITUDE = 0.5f;
      final float EXPONENT = 1f; 
      
      double x = this.x + (mouseX - width / 2) * -0.3;
      double y = this.y + (mouseY - height / 2) * -0.3;

      for (int pX = (int) Math.max(0, Math.min(width - 1, x - radius)); pX < x + radius; pX++) {
          if (pX >= height || pX <= 0) continue;

          for (int pY = (int) Math.max(0, Math.min(width - 1, y - radius)); pY < y + radius; pY++) {
              if (pY >= height || pY <= 0) continue;

              int index = (pY * width + pX);
              color pxClr = pixels[index];
              double dist = Math.sqrt(Math.pow(pX - x, 2) + Math.pow(pY - y, 2));

              if (dist > radius) continue;

              float falloff = (float) Math.pow(1 - (dist / radius), EXPONENT) * MAGNITUDE;
              pixels[index] = lerpColor(pxClr, clr, falloff);
          }
      }
  }
}

class Planet extends Star {
  Planet(double x, double y, double speed, double angle) {
    super(x, y, speed, angle);
    this.clr = color((int) (Math.random() * 64) + 64, (int) (Math.random() * 64) + 64, (int) (Math.random() * 64) + 64);
    targetSize = (float) (Math.random() * 3 + 2);
    realSize = targetSize * (float) Math.min(Math.random(), 0.5);
  }

  void draw() {
    pushMatrix();
    translate((float) x, (float) y);
    fill(clr);
    circle(0, 0, realSize * 2);
    popMatrix();
  }

  void shade() {
    // planets do not give off much light lol
    super.shade((int) (realSize), color(64));
  }
}

class Star extends Particle {
  float targetSize = 10;
  float realSize;
  int tickedPeriod = 0;

  Star(double x, double y, double speed, double angle) {
    super(x, y, speed, angle, color(255));
    targetSize = (float) (Math.random() * 10 + 5);
    realSize = targetSize * (float) Math.min(Math.random(), 0.5);
  }

  void tick() {
    super.tick();
    if (realSize < targetSize) {
      realSize += 0.1;
    }
    tickedPeriod++;
  }

  void draw() {
    if (tickedPeriod < 10) return;
    pushMatrix();
    translate((float) x, (float) y);
    fill(clr);
    circle(0, 0, realSize);
    popMatrix();
  }

  void shade() {
    if (tickedPeriod < 10) return;
    super.shade((int) (realSize * 3), color(128));
  }
}

class OddballParticle extends Particle {
  OddballParticle(double x, double y, double speed, double angle) {
    super(x, y, Math.max(speed, 3), angle, color(255));
  }

  void draw() {}

  void shade() {}

  void tick() {
    // super.tick();
    int ejectCount = (int) (Math.random() * 2) + 1;
    for (int i = 0; i < ejectCount; i++) {
      double ejectAngle = Math.random() * TWO_PI; 
      double ejectSpeed = Math.random() * 6;
      Particle p = Math.random() > 0.1
        ? new Star(x, y, ejectSpeed + speed * 2, ejectAngle)
        : new Planet(x, y, ejectSpeed + speed * 2, ejectAngle);
      particles.add(p);
    }
  }
}

class AmbientStar {
  double x, y;
  color clr;
  float lerpAmt;
  float targetLerpAmt;

  AmbientStar(double x, double y) {
    this.x = x;
    this.y = y;
    this.clr = color(255);
    lerpAmt = 1f;
  }

  void tick() {
    if (Math.abs(targetLerpAmt - lerpAmt) < 0.01) {
      targetLerpAmt = (float) (Math.random());
    }
    lerpAmt = lerp(lerpAmt, targetLerpAmt, 0.1f);
  }

  void draw() {
    pushMatrix();
    translate((float) x, (float) y);
    fill(lerpColor(clr, color(0), lerpAmt));
    circle(0, 0, 3);
    popMatrix();
  }
}
