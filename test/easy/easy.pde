/* Arduino C Program auto-generated by g2c.
 * g2c is Copyright 2009, Geordie and Chris Tilt and free to use and modify.
 * original G program:

	do 
		turn pin8 ON
		wait 50 msec
		turn pin8 OFF
		wait 1000 msec
	forver
*/
int pin8 = 8;

void setup() {
  pinMode(pin8, OUTPUT);
}

void loop() {
  // repeat sequentially
  while (1) {
    digitalWrite(pin8,HIGH);
    delay(50);
    digitalWrite(pin8,LOW);
    delay(1000);
  }
}

