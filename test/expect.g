        blink pin1 every 500 msec for 50 times
        blink pin2 every 1500 msec for 1 times
        do 
                blink pin1 every 500 msec for 50 times
                blink pin1 every 500 msec for 50 times
        until 3 times
        repeat 
                blink pin3 every 1000 msec for 2000 msec
                blink pin4 every 1000 msec for 1 times
                blink pin4 every 1500 msec for 1 times
        until 2 times
        if detect pin5 is ON blink pin3 every 1000 msec for 5 times
        if detect pin5 is ON blink pin3 every 500 msec for 5 times and turn pin7 OFF
        repeat 
                if detect pin5 is ON blink pin3 every 500 msec for 3000 msec
                turn pin7 ON
                wait 2000 msec
                turn pin7 OFF
                wait 25 msec
        until 3000 msec
        do 
                blink pin4 every 1000 msec for 1 times
                blink pin4 every 1500 msec for 1 times
        while detect pin5 is OFF
