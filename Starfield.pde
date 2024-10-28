import java.util.*;

ArrayList<Particle> particles;

color framebufferColor = color(32);

final int NUM_PARTICLES = 100;
final int MAX_CULL_DEV = 10;

void setup() {
  pixelDensity(1);
  // size(512, 512, P3D);
  size(512, 512);

  particles = new ArrayList<>();
  for (int i = 0; i < NUM_PARTICLES; i++) {
    particles.add(randomParticle(this));
  }
  particles.add(new OddballParticle(width / 2, width / 2, 1, 0));
}

void draw() {
  background(framebufferColor);
  ArrayList<Particle> pendingCull = new ArrayList<>();

  // bulk loading/writing of framebuffer
  // is a cpu shader optimal? no. is it optimal to read from the gpu, shade it on the cpu, and write it back? no.
  // but yes
  loadPixels();
  
  ArrayList<Particle> current = particles;
  particles = (ArrayList<Particle>) particles.clone();
  for (Particle parc : current) {
    if (parc.x > width + MAX_CULL_DEV || parc.x < -MAX_CULL_DEV || parc.y > height + MAX_CULL_DEV || parc.y < -MAX_CULL_DEV) {
      pendingCull.add(parc);
    } else {
      parc.tick();
      parc.shade();
    }
  }
  updatePixels();

  for (Particle parc : pendingCull) particles.remove(parc);

  for (Particle parc : particles) parc.draw();

  int pending = NUM_PARTICLES - particles.size();
  if (pending > 0) {
    for (int i = 0; i < pending; i++) {
      particles.add(randomParticle(this));
    }
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
    x += speed * Math.cos(angle);
    y += speed * Math.sin(angle);
    speed *= fric;
  }

  void draw() {
    push();
    translate((float) x, (float) y);
    fill(clr);
    circle(0, 0, 10);
    pop();
  }

  void shade() {
    this.shade(20, color(128));
  }

  void shade(int radius, color clr) {
    final float MAGNITUDE = 0.3f;
    for (int pX = (int) Math.max(0, Math.min(width - 1, x - radius)); pX < x + radius; pX++) {
      if (pX >= height || pX <= 0) continue;
      for (int pY = (int) Math.max(0, Math.min(width - 1, y - radius)); pY < y + radius; pY++) {
      if (pY >= height || pY <= 0) continue;
        int index = (pY * width + pX);
        color pxClr = pixels[index];
        double dist = Math.sqrt(Math.pow(pX - x, 2) + Math.pow(pY - y, 2));
        if (dist > radius) continue;
        pixels[index] = lerpColor(pxClr, clr, (float) (1 - ((dist / radius))) * MAGNITUDE);
      }
    }
  }
}

class Star extends Particle {
  float targetSize = 10;
  float realSize = 1;

  Star(double x, double y, double speed, double angle) {
    super(x, y, speed, angle, color(255));
  }

  void tick() {
    super.tick();
    if (realSize < targetSize) {
      realSize += 0.1;
    }
  }
}

class OddballParticle extends Particle {
  OddballParticle(double x, double y, double speed, double angle) {
    super(x, y, speed, angle, color(255));
  }

  void tick() {
    // super.tick();
    int ejectCount = (int) (Math.random() * 2) + 1;
    for (int i = 0; i < ejectCount; i++) {
      double ejectAngle = Math.random() * TWO_PI; 
      double ejectSpeed = Math.random() * 6;
      Particle p = new Star(x, y, ejectSpeed + speed * 2, ejectAngle);
      particles.add(p);
    }
  }
}

