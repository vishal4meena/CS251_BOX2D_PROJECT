.SUFFIXES: .cpp .hpp

# Programs
SHELL 	= bash
CC     	= g++
LD	= ld
RM 	= rm
ECHO	= /bin/echo
CAT	= cat
PRINTF	= printf
SED	= sed
DOXYGEN = doxygen
GPROF = gprof
PYTHON = python3
MV = mv
DOT = dot
######################################
# Project Name (generate executable with this name)
TARGET = gate_opener_debug
RTARGET = = gate_opener_release

# Project Paths
PROJECT_ROOT=./
EXTERNAL_ROOT=$(PROJECT_ROOT)/external
SRCDIR = $(PROJECT_ROOT)/src
OBJDIR = $(PROJECT_ROOT)/obj
BINDIR = $(PROJECT_ROOT)/bin
SRCEXT = $(EXTERNAL_ROOT)/src
DOCDIR = $(PROJECT_ROOT)/doc
PYTHON_FILE = gprof2dot.py

# Library Paths
BOX2D_ROOT=$(EXTERNAL_ROOT)
GLUI_ROOT=/usr
GL_ROOT=/usr/include/

#Libraries
LIBS = -lBox2D -lglui -lglut -lGLU -lGL

# Compiler and Linker flags
CPPFLAGS =-g -Wall -pg -fno-strict-aliasing
CPPFLAGS+=-I $(BOX2D_ROOT)/include -I $(GLUI_ROOT)/include
LDFLAGS = -pg -L $(BOX2D_ROOT)/lib -L $(GLUI_ROOT)/lib
RCPPFLAGS =-O3 -Wall -pg -fno-strict-aliasing
RCPPFLAGS+=-I $(BOX2D_ROOT)/include -I $(GLUI_ROOT)/include
######################################

NO_COLOR=\e[0m
OK_COLOR=\e[1;32m
ERR_COLOR=\e[1;31m
WARN_COLOR=\e[1;33m
MESG_COLOR=\e[1;34m
FILE_COLOR=\e[1;37m

OK_STRING="[OK]"
ERR_STRING="[ERRORS]"
WARN_STRING="[WARNINGS]"
OK_FMT="${OK_COLOR}%30s\n${NO_COLOR}"
ERR_FMT="${ERR_COLOR}%30s\n${NO_COLOR}"
WARN_FMT="${WARN_COLOR}%30s\n${NO_COLOR}"
######################################

SRCS := $(wildcard $(SRCDIR)/*.cpp)
INCS := $(wildcard $(SRCDIR)/*.hpp)
OBJS := $(SRCS:$(SRCDIR)/%.cpp=$(OBJDIR)/%.o)
OBJECTS := $(SRCS:$(SRCDIR)/%.cpp=$(OBJDIR)/%.o)


.PHONY: all setup codeDoc clean distclean profile release

all: setup $(BINDIR)/$(TARGET)

setup:
	@$(ECHO) "Setting up compilation..."
	@mkdir -p obj
	@mkdir -p bin

b2dsetup:
	@if ! test -d $(SRCEXT)/Box2D; \
	then tar zxf $(SRCEXT)/Box2D.tgz -C $(SRCEXT); \
	else LSB2D=$$(ls -A $(SRCEXT)/Box2D); \
	if test -z "$$LSB2D"; \
	then tar zxf $(SRCEXT)/Box2D.tgz -C $(SRCEXT); \
	fi; \
	fi
	@mkdir -p $(SRCEXT)/Box2D/build251
	@{ \
	set -e ;\
	cd $(SRCEXT)/Box2D/build251 ;\
	cmake ../ ;\
	make ;\
	make install ;\
	}

$(BINDIR)/$(TARGET): $(OBJS)
	@$(PRINTF) "$(MESG_COLOR)Building executable:$(NO_COLOR) $(FILE_COLOR) %16s$(NO_COLOR)" "$(notdir $@)"
	@$(CC) -o $@ $(LDFLAGS) $(OBJS) $(LIBS) 2> temp.log || touch temp.err
	@if test -e temp.err; \
	then $(PRINTF) $(ERR_FMT) $(ERR_STRING) && $(CAT) temp.log; \
	elif test -s temp.log; \
	then $(PRINTF) $(WARN_FMT) $(WARN_STRING) && $(CAT) temp.log; \
	else $(PRINTF) $(OK_FMT) $(OK_STRING); \
	fi;
	@$(RM) -f temp.log temp.err

-include -include $(OBJS:.o=.d)

$(OBJS): $(OBJDIR)/%.o : $(SRCDIR)/%.cpp
	@$(PRINTF) "$(MESG_COLOR)Compiling: $(NO_COLOR) $(FILE_COLOR) %25s$(NO_COLOR)" "$(notdir $<)"
	@$(CC) $(CPPFLAGS) -c $< -o $@ -MD 2> temp.log || touch temp.err
	@if test -e temp.err; \
	then $(PRINTF) $(ERR_FMT) $(ERR_STRING) && $(CAT) temp.log; \
	elif test -s temp.log; \
	then $(PRINTF) $(WARN_FMT) $(WARN_STRING) && $(CAT) temp.log; \
	else printf "${OK_COLOR}%30s\n${NO_COLOR}" "[OK]"; \
	fi;
	@$(RM) -f temp.log temp.err

codeDoc:
	@$(ECHO) -n "Generating Doxygen Documentation ...  "
	@$(RM) -rf doc/html
	@$(DOXYGEN) $(DOCDIR)/Doxyfile 2 > /dev/null
	@$(ECHO) "Done"

clean:
	@$(ECHO) -n "Cleaning up..."
	@$(RM) -rf $(OBJDIR) *~ $(DEPS) $(SRCDIR)/*~
	@$(ECHO) "Done"

distclean: clean
	@$(RM) -rf $(BINDIR) $(DOCDIR)/html $(EXTERNAL_ROOT)/include/* $(EXTERNAL_ROOT)/lib/* $(SRCEXT)/Box2D  $(DOCDIR)/*.png


profile: setup $(BINDIR)/$(TARGET)
	@$(ECHO) "Run the simulation till where profiling needs to be done..."
	@./$(BINDIR)/$(TARGET)
	@$(MV) gmon.out $(BINDIR)/gmon.out
	@$(GPROF) $(BINDIR)/$(TARGET) $(BINDIR)/gmon.out > gprof_output.txt
	@$(PYTHON) $(PYTHON_FILE) gprof_output.txt > $(DOCDIR)/profile.dot
	@$(DOT) -Tpng $(DOCDIR)/profile.dot > $(DOCDIR)/profile.png
	@$(RM) $(DOCDIR)/*.dot gprof_output.txt

report:


release: distclean $(BINDIR)/$(RTARGET)
