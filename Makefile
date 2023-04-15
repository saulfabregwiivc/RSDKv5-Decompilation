.DEFAULT_GOAL := all

PKGCONFIG	=  pkg-config
STRIP		?= strip

STATIC		?= 1
DEBUG		?= 1
VERBOSE		?= 0
PROFILE		?= 0

RSDK_ONLY   ?= 0

RETRO_REVISION ?= 3
RSDK_REVISION  ?= $(RETRO_REVISION)

ifeq ($(RSDK_REVISION),3)
RSDK_NAME    = RSDKv5U
else
RSDK_NAME    = RSDKv5
endif
RSDK_SUFFIX  = 
USERTYPE    ?= Dummy

RSDK_CFLAGS  =
RSDK_LDFLAGS =
RSDK_LIBS    =

RSDK_PREBUILD =
RSDK_PRELINK  =

STATICGAME 	?= 0

ifeq ($(RSDK_ONLY),0)
GAME_NAME   ?= Game
GAME_SUFFIX ?= .so
GAME_ALLC   ?= 1

GAME_CFLAGS  =
GAME_LDFLAGS = -shared
GAME_LIBS    =

GAME_PREBUILD =
GAME_PRELINK  =
endif

DEFINES      ?=

ifneq ($(AUTOBUILD),)
	DEFINES += -DRSDK_AUTOBUILD
endif


# =============================================================================
# Detect default platform if not explicitly specified
# =============================================================================

ifeq ($(OS),Windows_NT)
	PLATFORM ?= Windows
else
	UNAME_S := $(shell uname -s)

	ifeq ($(UNAME_S),Linux)
		PLATFORM ?= Linux
	endif

	ifeq ($(UNAME_S),Darwin)
		PLATFORM ?= macOS
	endif

endif

PLATFORM ?= Unknown

# =============================================================================

RSDK_SOURCES =

ifneq ("$(wildcard makefiles/$(PLATFORM).cfg)","")
	include makefiles/$(PLATFORM).cfg
endif

DEFINES += -DRSDK_USE_$(SUBSYSTEM)

OUTDIR = bin/$(PLATFORM)/$(SUBSYSTEM)
RSDK_OBJDIR = bin/obj/$(PLATFORM)/$(SUBSYSTEM)/RSDKv5
GAME_OBJDIR = bin/obj/$(PLATFORM)/$(GAME_NAME)


# =============================================================================

CFLAGS ?= $(CXXFLAGS)
DEFINES += -DBASE_PATH='"$(BASE_PATH)"'

ifeq ($(DEBUG),1)
	CXXFLAGS += -g
	CFLAGS += -g
	STRIP = :
else
	CXXFLAGS += -O3
	CFLAGS += -O3
endif

ifeq ($(STATIC),1)
	CXXFLAGS += -static
	CFLAGS += -static
endif

ifeq ($(PROFILE),1)
	CXXFLAGS += -pg -g -fno-inline-functions -fno-inline-functions-called-once -fno-optimize-sibling-calls -fno-default-inline
	CFLAGS += -pg -g -fno-inline-functions -fno-inline-functions-called-once -fno-optimize-sibling-calls -fno-default-inline
endif

ifeq ($(VERBOSE),0)
	CC := @$(CC)
	CXX := @$(CXX)
endif

ifeq ($(STATICGAME),0)
	DEFINES += -DRETRO_STANDALONE=1
else
	DEFINES += -DRETRO_STANDALONE=0
endif

DEFINES += -DRETRO_REVISION=$(RSDK_REVISION)

ifeq ($(RSDK_REVISION),1) 
DEFINES += -DMANIA_PREPLUS=1
endif

CFLAGS_ALL += $(CFLAGS) \
			   -fsigned-char 
		
CXXFLAGS_ALL += $(CXXFLAGS) \
			   -std=c++17 \
			   -fsigned-char \
			   -fpermissive 

LDFLAGS_ALL = $(LDFLAGS)

RSDK_INCLUDES  += \
	-I./RSDKv5/ 					\
	-I./dependencies/all/ 			\
	-I./dependencies/all/tinyxml2/ 	\
	-I./dependencies/all/iniparser/

# Main Sources
RSDK_SOURCES += \
	RSDKv5/main 							\
	RSDKv5/RSDK/Core/RetroEngine  			\
	RSDKv5/RSDK/Core/Math         			\
	RSDKv5/RSDK/Core/Reader       			\
	RSDKv5/RSDK/Core/Link        			\
	RSDKv5/RSDK/Core/ModAPI       			\
	RSDKv5/RSDK/Dev/Debug        			\
	RSDKv5/RSDK/Storage/Storage       		\
	RSDKv5/RSDK/Storage/Text         		\
	RSDKv5/RSDK/Graphics/Drawing      		\
	RSDKv5/RSDK/Graphics/Scene3D      		\
	RSDKv5/RSDK/Graphics/Animation    		\
	RSDKv5/RSDK/Graphics/Sprite       		\
	RSDKv5/RSDK/Graphics/Palette      		\
	RSDKv5/RSDK/Graphics/Video     			\
	RSDKv5/RSDK/Audio/Audio        			\
	RSDKv5/RSDK/Input/Input        			\
	RSDKv5/RSDK/Scene/Scene        			\
	RSDKv5/RSDK/Scene/Collision    			\
	RSDKv5/RSDK/Scene/Object       			\
	RSDKv5/RSDK/Scene/Objects/DefaultObject \
	RSDKv5/RSDK/Scene/Objects/DevOutput     \
	RSDKv5/RSDK/User/Core/UserAchievements  \
	RSDKv5/RSDK/User/Core/UserCore     		\
	RSDKv5/RSDK/User/Core/UserLeaderboards  \
	RSDKv5/RSDK/User/Core/UserPresence     	\
	RSDKv5/RSDK/User/Core/UserStats     	\
	RSDKv5/RSDK/User/Core/UserStorage     	\
	dependencies/all/tinyxml2/tinyxml2 		\
	dependencies/all/iniparser/iniparser 	\
	dependencies/all/iniparser/dictionary   \
	dependencies/all/miniz/miniz   

ifeq ($(RSDK_ONLY),0)
GAME_INCLUDES = \
	-I./$(GAME_NAME)/   		\
	-I./$(GAME_NAME)/Objects/

GAME_SOURCES = \
	$(GAME_NAME)/Game

ifeq ($(GAME_ALLC),1)
GAME_SOURCES += $(GAME_NAME)/Objects/All
else
# execute Game/objectmake.py?
include $(GAME_NAME)/Objects.cfg
endif
endif

RSDK_PATH = $(OUTDIR)/$(RSDK_NAME)$(RSDK_SUFFIX)

PKG_NAME 	?= $(RSDK_NAME)
PKG_SUFFIX 	?= $(RSDK_SUFFIX)
PKG_PATH 	 = $(OUTDIR)/$(PKG_NAME)$(PKG_SUFFIX)

RSDK_OBJECTS += $(addprefix $(RSDK_OBJDIR)/, $(addsuffix .o, $(RSDK_SOURCES)))

$(shell mkdir -p $(OUTDIR))
$(shell mkdir -p $(RSDK_OBJDIR))

ifeq ($(RSDK_ONLY),0)
GAME_OBJECTS += $(addprefix $(GAME_OBJDIR)/, $(addsuffix .o, $(GAME_SOURCES)))
GAME_PATH = $(OUTDIR)/$(GAME_NAME)$(GAME_SUFFIX)
$(shell mkdir -p $(GAME_OBJDIR))

$(GAME_OBJDIR)/%.o: $(GAME_PREBUILD) %.c
	@mkdir -p $(@D)
	@echo compiling $<...
	$(CC) -c $(CFLAGS_ALL) $(GAME_FLAGS) $(GAME_INCLUDES) $(DEFINES) $< -o $@
	@echo done $<
endif

$(RSDK_OBJDIR)/%.o: %.c
	@mkdir -p $(@D)
	@echo compiling $<...
	$(CC) -c $(CFLAGS_ALL) $(RSDK_CFLAGS) $(RSDK_INCLUDES) $(DEFINES) $< -o $@
	@echo done $<

$(RSDK_OBJDIR)/%.o: $(RSDK_PREBUILD) %.cpp
	@mkdir -p $(@D)
	@echo compiling $<...
	$(CXX) -c $(CXXFLAGS_ALL) $(RSDK_CFLAGS) $(RSDK_INCLUDES) $(DEFINES) $< -o $@
	@echo done $<

ifeq ($(STATICGAME),1)
$(RSDK_PATH): $(RSDK_PRELINK) $(RSDK_OBJECTS) $(GAME_OBJECTS)
	@echo linking...
	$(CXX) $(CXXFLAGS_ALL) $(LDFLAGS_ALL) $(RSDK_LDFLAGS) $(RSDK_OBJECTS) $(GAME_OBJECTS) $(RSDK_LIBS) $(GAME_LIBS) -o $@ 
	$(STRIP) $@
	@echo done
else # STATICGAME
$(RSDK_PATH): $(RSDK_PRELINK) $(RSDK_OBJECTS)
	@echo linking RSDK...
	$(CXX) $(CXXFLAGS_ALL) $(LDFLAGS_ALL) $(RSDK_LDFLAGS) $(RSDK_OBJECTS) $(RSDK_LIBS) -o $@ 
	$(STRIP) $@
	@echo done linking RSDK
ifeq ($(RSDK_ONLY),0)
$(GAME_PATH): $(GAME_PRELINK) $(GAME_OBJECTS)
	@echo linking game...
	$(CXX) $(CXXFLAGS_ALL) $(LDFLAGS_ALL) $(GAME_LDFLAGS) $(GAME_OBJECTS) $(GAME_LIBS) -o $@ 
	$(STRIP) $@
	@echo done linking game
endif # RSDK_ONLY
endif # STATICGAME


ifeq ($(RSDK_PATH),$(PKG_PATH))

ifeq ($(STATICGAME),1)
all: $(RSDK_PATH)
else # STATICGAME

ifeq ($(RSDK_ONLY),0)
all: $(RSDK_PATH) $(GAME_PATH)
else # RSDK_ONLY
all: $(RSDK_PATH)
endif # RSDK_ONLY

endif # STATICGAME

else # PKGPATH
all: $(PKG_PATH)
endif # PKGPATH

clean-rsdk:
	rm -rf $(RSDK_PATH) && rm -rf $(RSDK_OBJDIR)

clean-game:
	rm -rf $(GAME_PATH) && rm -rf $(GAME_OBJDIR)

ifeq ($(RSDK_PATH),$(PKG_PATH))
clean: clean-rsdk clean-game 
else
clean: clean-rsdk clean-game
	rm -rf $(PKG_PATH)
endif
