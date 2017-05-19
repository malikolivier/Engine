DIRS  = \
	*.vala \
	Audio/*.vala \
	Files/*.vala \
	Helper/*.vala \
	Properties/*.vala \
	Rendering/*.vala \
	Rendering/OpenGLRenderer/*.vala \
	Rendering/OpenGLRenderer/Shaders/*.vala \
	Rendering/World/*.vala \
	Window/*.vala \
	Window/Controls/*.vala

PKGS  = \
	--thread \
	--pkg gio-2.0 \
	--pkg glew \
	--pkg gee-0.8 \
	--pkg gl \
	--pkg SDL2_image \
	--pkg sdl2 \
	--pkg stb \
	--pkg pangoft2 \
	--pkg sfml-audio \
	--pkg sfml-system \
	--pkg zlib \
	-X -Iinclude \
	-X -lcsfml-audio \
	-X -lcsfml-system \
	-X -lm

WINDOWS = \
	-X -lopengl32

MAC = \
	-X -framework -X OpenGL \
	-X -framework -X CoreFoundation

VALAC = valac
NAME  = libengine
OUT   = bin/$(NAME)
VAPI  = --vapidir=vapi
#-w = Supress C warnings (Since they stem from the vala code gen)
OTHER = -X -w -X -DGLEW_NO_GLU
O     = --library=$(NAME) --vapi $(OUT).vapi -X -shared -H $(OUT).h -o $(OUT)
DEBUG = -v --save-temps --enable-checking -g -X -ggdb -X -O0 -D DEBUG

all: release

debug:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(VAPI) $(OTHER) $(DEBUG) -D LINUX

release:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(VAPI) $(OTHER) -D LINUX

macDebug:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(MAC) $(VAPI) $(OTHER) $(DEBUG) -D MAC

mac:
	$(VALAC) $(O) $(DIRS) $(PKGS) $(MAC) $(VAPI) $(OTHER) -D MAC

windowsDebug:
	$(VALAC) $(O).dll $(DIRS) $(PKGS) $(WINDOWS) $(VAPI) $(OTHER) $(DEBUG) -D WINDOWS

windows:
	$(VALAC) $(O).dll $(DIRS) $(PKGS) $(WINDOWS) $(VAPI) $(OTHER) -D WINDOWS -X -mwindows

clean:
	rm -f $(OUT)*
	/usr/bin/find . -type f -name '*.c' -exec rm {} +