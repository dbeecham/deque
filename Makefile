
CFLAGS         = -fPIC -Iinclude -Wall -Wextra -Wno-used-result \
                 -Wno-implicit-fallthrough -Wno-unused-const-variable \
                 -std=c11 -g3 -Os -D_FORTIFY_SOURCE=2 -fexceptions \
                 -fasynchronous-unwind-tables \
                 -fstack-protector-strong -grecord-gcc-switches \
                 -Werror=format-security \
                 -Werror=implicit-function-declaration -Wl,-z,defs -Wl,-z,now \
                 -Wl,-z,relro -Wno-unused-but-set-variable \
                 $(EXTRA_CFLAGS)
LDFLAGS        = -fPIC $(EXTRA_LDFLAGS)
LDLIBS         = -pthread $(EXTRA_LDLIBS)
DESTDIR        = /
PREFIX         = /usr/local
RAGEL          = ragel
RAGELFLAGS     = -G2 $(EXTRA_RAGELFLAGS)
INSTALL        = install
BEAR           = bear
COMPLEXITY     = complexity
CFLOW          = cflow
NEATO          = neato
CTAGS          = ctags
Q              = @
CC_COLOR       = \033[0;34m
LD_COLOR       = \033[0;33m
TEST_COLOR     = \033[0;35m
INSTALL_COLOR  = \033[0;32m
NO_COLOR       = \033[m


# Main rule - the library.

libdeque.so: deque.o


#################
# INSTALL RULES #
#################
# {{{

# Target directories - create them if they do not exist.
$(DESTDIR)$(PREFIX)/lib:
	@echo "$(INSTALL_COLOR)INSTALL$(NO_COLOR) $(DESTDIR)$(PREFIX)/lib"
	$(Q)$(INSTALL) -d $(DESTDIR)$(PREFIX)/lib

$(DESTDIR)$(PREFIX)/include:
	@echo "$(INSTALL_COLOR)INSTALL$(NO_COLOR) $(DESTDIR)$(PREFIX)/include"
	$(Q)$(INSTALL) -d $(DESTDIR)$(PREFIX)/include


install: libdeque.so | $(DESTDIR)$(PREFIX)/lib $(DESTDIR)$(PREFIX)/include
	@echo "$(INSTALL_COLOR)INSTALL$(NO_COLOR) $(DESTDIR)$(PREFIX)/lib/libdeque.so"
	$(Q)$(INSTALL) -m 0644 libdeque.so $(DESTDIR)$(PREFIX)/lib/
	@echo "$(INSTALL_COLOR)INSTALL$(NO_COLOR) $(DESTDIR)$(PREFIX)/include/deque.h"
	$(Q)$(INSTALL) -m 0644 include/deque.h $(DESTDIR)$(PREFIX)/include/

# }}}


#########
# TESTS #
#########

test: CFLAGS += -I./vendor/munit/ -fprofile-arcs -ftest-coverage 
test: LDLIBS += -lgcov --coverage
test: test_driver
	@echo "$(TEST_COLOR)TEST$(NO_COLOR)  $@"
	$(Q)./test_driver && gcov deque.o && gcovr -r . -e ".*munit.c" -e "tests/test_.*.c"

check: CFLAGS += -I./vendor/munit/
check: test_driver
	./test_driver

test_driver: test_driver.o test_deque.o munit.o deque.o
	@echo "$(LD_COLOR)LD$(NO_COLOR) $@"
	$(Q)$(CC) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)


#########################
# DEVELOPMENT UTILITIES #
#########################
# {{{

.PHONY: complexity
complexity:
	$(COMPLEXITY) --scores --threshold=1 src/*.c

.PHONY: ci
ci: | cscope.files
	find . -name "*.c" -o -name "*.h" -o -name "*.rl" -o -iname "Makefile" | entr make -B

.PHONY: ci-test
ci-test: | cscope.files
	find . -name "*.c" -o -name "*.h" -o -name "*.rl" -o -iname "Makefile" | entr make -B test

.PHONY: cscope
cscope: | cscope.files
	cscope -b -q -k

.PHONY: compile_commands.json
compile_commands.json:
	$(BEAR) $(MAKE) -B test

.PHONY: tags
tags: | cscope.files
	$(CTAGS) -L cscope.files

# }}}



#################
# CLEAN TARGETS #
#################

clean:
	rm -f *.o test_driver *.gcda *.gcno *.gcov *.cflow

distclean: clean
	rm -f *.so cnatsd


################
# SOURCE PATHS #
################
# {{{

vpath %.c src/
vpath %.c.rst src/
vpath %.c.md src/
vpath %.c.rl src/
vpath %.c.rl.md src/
vpath %.c.rl.rst src/
vpath %.h include/
vpath munit.c vendor/munit/
vpath test_%.c tests/

# }}}


##################
# IMPLICIT RULES #
##################
# {{{

%.so:
	@echo "$(LD_COLOR)LD$(NO_COLOR) $@"
	$(Q)$(CC) $(LDFLAGS) -shared -o $@ $^ $(LOADLIBES) $(LDLIBS)

%.o: %.c
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $^

# for each c file, it's possible to generate a cflow flow graph.
%.c.cflow: %.c
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(CFLOW) -o $@ $<

%.png: %.dot
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(NEATO) -Tpng -Ln100 -o $@ $<

%.dot: %.rl
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(RAGEL) $(RAGELFLAGS) -V -p $< -o $@

%.c: %.c.rl
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)$(RAGEL) -Iinclude $(RAGELFLAGS) -o $@ $<

%.c: %.c.rst
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)cat $< | rst_tangle > $@

# build c files from markdown files - literate programming style
%.c: %.c.md
	@echo "$(CC_COLOR)CC$(NO_COLOR) $@"
	$(Q)cat $< | sed -n '/^```c/,/^```/ p' | sed '/^```/ d' > $@

# }}}
