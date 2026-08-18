BINARY   := TabRat
SRC      := TabRat.swift
BINDIR   := $(HOME)/bin
LABEL    := com.claytonketner.tabrat
PLIST    := $(HOME)/Library/LaunchAgents/$(LABEL).plist

.PHONY: all build install load unload reload perms clean

all: build

build: $(BINARY)

$(BINARY): $(SRC)
	swiftc -O $(SRC) -o $(BINARY)

install: build
	mkdir -p $(BINDIR)
	cp $(BINARY) $(BINDIR)/$(BINARY)
	@echo "Installed to $(BINDIR)/$(BINARY)"

load:
	launchctl bootstrap gui/$$(id -u) $(PLIST)

unload:
	-launchctl bootout gui/$$(id -u)/$(LABEL)

# Rebuild, reinstall, and restart the LaunchAgent in one step.
reload: unload install load

# Open System Settings directly to the Accessibility permissions pane, then
# show a dialog with the exact steps (including the delete-and-recreate
# dance needed after every rebuild).
perms:
	open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
	@osascript -e 'display dialog "TabRat needs Accessibility permission.\n\nIn the window that just opened:\n\n1. If TabRat is already listed, select it and click the − button to remove it (each rebuild produces a new, unsigned binary — the old entry does not cover it).\n2. Click the + button.\n3. Press Cmd+Shift+G, type ~/bin/, and select TabRat.\n4. Click Open, and make sure its toggle is on.\n\nThen back in Terminal, run: make reload" with title "TabRat: Accessibility Permission" buttons {"OK"} default button "OK"' > /dev/null

clean:
	rm -f $(BINARY)
