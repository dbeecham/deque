CFLAGS += -O0 -g3 -Iinclude -fPIC -Wall -Wextra -Wno-unused-but-set-variable
LDLIBS += -pthread

vpath %.c src
vpath test_%.c tests
vpath munit.c vendor/munit/
vpath %.rl src

%.c: %.c.rl
	ragel -G2 -o $@ $<

libdeque.so: deque.o
	$(CC) -shared -o $@ $<


.PHONY: test
test: CFLAGS += -I./vendor/munit/
test: test_driver

test_driver: test_driver.o test_deque.o munit.o deque.o


.PHONY: compile_commands.json
compile_commands.json: 
	bear make -B tests


clean:
	rm -f *.o *.so test_driver
