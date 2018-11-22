
# Invoke `make` to build, `make clean` to clean up, etc.

.PHONY: default all utop test clean

default: all

# Build one library and one standalone executable that implements
# multiple subcommands and uses the library.
# The library can be loaded in utop for interactive testing.
all:
	jbuilder build @install
	@test -L bin || ln -s _build/install/default/bin .

# Launch utop such that it finds our library.
utop: all
	jbuilder utop src/lib

# Build and run tests
test: all
	jbuilder runtest

# Clean up
clean:
# Remove files produced by jbuilder.
	jbuilder clean
# Remove remaining files/folders ignored by git as defined in .gitignore (-X).
	git clean -dfXq