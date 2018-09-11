CFLAGS = -O0 -g3 -Iinclude -fPIC -Wall -Wextra -Wno-unused-but-set-variable $(EXTRA_CFLAGS)
LDFLAGS = $(EXTRA_LDFLAGS)
LDLIBS = -pthread $(EXTRA_LDLIBS)
DESTDIR = /
PREFIX = /usr
RAGEL = ragel
RAGELFLAGS = -G2
INSTALL = install
CFLOW = cflow
BEAR = bear
COMPLEXITY = complexity

vpath %.c src
vpath test_%.c tests
vpath munit.c vendor/munit/
vpath %.rl src


# IMPLICIT RULES

# for each c file, it's possible to generate a cflow flow graph.
%.c.cflow: %.c
	$(CFLOW) -o $@ $<

# C files can be generated from ragel files, if they exist.
%.c: %.c.rl
	$(RAGEL) $(RAGELFLAGS) -o $@ $<



# Main rule - the library.

libdeque.so: deque.o
	$(CC) -shared -o $@ $<


#################
# INSTALL RULES #
#################

# Target directories - create them if they do not exist.
$(DESTDIR)$(PREFIX)/lib:
	$(INSTALL) -d $(DESTDIR)$(PREFIX)/lib

$(DESTDIR)$(PREFIX)/include:
	$(INSTALL) -d $(DESTDIR)$(PREFIX)/include

install: libdeque.so | $(DESTDIR)$(PREFIX)/lib $(DESTDIR)$(PREFIX)/include
	$(INSTALL) -m 0644 libdeque.so $(DESTDIR)$(PREFIX)/lib/
	$(INSTALL) -m 0644 include/deque.h $(DESTDIR)$(PREFIX)/include/



#########
# TESTS #
#########

test: CFLAGS += -I./vendor/munit/ -fprofile-arcs -ftest-coverage 
test: LDLIBS += -lgcov --coverage
test: test_driver
	./test_driver && gcov deque.o && gcovr -r . -e ".*munit.c" -e "tests/test_.*.c"

check: CFLAGS += -I./vendor/munit/
check: test_driver
	./test_driver

test_driver: test_driver.o test_deque.o munit.o deque.o


#########################
# DEVELOPMENT UTILITIES #
#########################

.PHONY: compile_commands.json
compile_commands.json:
	$(BEAR) $(MAKE) -B test


.PHONY: complexity
complexity:
	$(COMPLEXITY) --scores --threshold=1 src/*.c

.PHONY: ci
ci:
	find . -name "*.c" -o -name "*.h" -o -name "*.rl" -o -iname "Makefile" | entr make -B test

clean:
	rm -f *.o test_driver

distclean: clean
	rm -f *.so
