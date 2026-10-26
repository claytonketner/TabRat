// TabRat.swift
//
// TabRat: intercepts otherMouseDown events for the side buttons
// (button=3, button=4) and, ONLY when a recognized web browser is the
// frontmost app, consumes them and synthesizes Cmd+Option+Left /
// Cmd+Option+Right keyboard events instead (Cmd+Shift+[ / ] in Safari). In every other app, or for
// every other button, the original event is passed through untouched.

import Cocoa
import CoreGraphics

// MARK: - Config

// Bundle identifiers of browsers to remap in. Add/remove as needed.
let targetBundleIDs: Set<String> = [
    "com.google.Chrome",
    "com.google.Chrome.beta",
    "com.google.Chrome.canary",
    "com.apple.Safari",
    "com.apple.SafariTechnologyPreview",
    "org.mozilla.firefox",
    "org.mozilla.firefoxdeveloperedition",
    "com.microsoft.edgemac",
    "com.microsoft.edgemac.Dev",
    "com.microsoft.edgemac.Beta",
    "com.brave.Browser",
    "com.brave.Browser.beta",
    "com.brave.Browser.nightly",
    "com.operasoftware.Opera",
    "com.operasoftware.OperaGX",
    "com.vivaldi.Vivaldi",
    "company.thebrowser.Browser", // Arc
]

// Safari doesn't support Cmd+Opt+Arrow for tab switching; it uses
// Cmd+Shift+[ / Cmd+Shift+] instead.
let safariBundleIDs: Set<String> = [
    "com.apple.Safari",
    "com.apple.SafariTechnologyPreview",
]

let kVK_LeftArrow: CGKeyCode = 123
let kVK_RightArrow: CGKeyCode = 124
let kVK_ANSI_LeftBracket: CGKeyCode = 33
let kVK_ANSI_RightBracket: CGKeyCode = 30

// MARK: - Synthetic key events

func postKey(keyCode: CGKeyCode, flags: CGEventFlags) {
    guard let source = CGEventSource(stateID: .hidSystemState) else { return }

    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    keyDown?.flags = flags

    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    keyUp?.flags = flags

    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}

// MARK: - Event tap callback

let eventMask: CGEventMask =
    (1 << CGEventType.otherMouseDown.rawValue) |
    (1 << CGEventType.otherMouseUp.rawValue)

func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = globalEventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)

    // otherMouseUp is never remapped or consumed — log it and pass it through.
    guard type == .otherMouseDown else {
        print("otherMouseUp   button=\(buttonNumber)")
        fflush(stdout)
        return Unmanaged.passUnretained(event)
    }

    print("otherMouseDown button=\(buttonNumber)")
    fflush(stdout)

    guard buttonNumber == 3 || buttonNumber == 4 else {
        return Unmanaged.passUnretained(event)
    }

    let frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    guard let bundleID = frontmostBundleID, targetBundleIDs.contains(bundleID) else {
        // Not a recognized browser — leave back/forward (or whatever the
        // button normally does) working as usual in every other app.
        return Unmanaged.passUnretained(event)
    }

    let isNext = buttonNumber == 3
    if safariBundleIDs.contains(bundleID) {
        postKey(keyCode: isNext ? kVK_ANSI_RightBracket : kVK_ANSI_LeftBracket,
                flags: [.maskCommand, .maskShift])
    } else {
        postKey(keyCode: isNext ? kVK_RightArrow : kVK_LeftArrow,
                flags: [.maskCommand, .maskAlternate])
    }

    // Consume: don't let the browser also see the raw mouse-button event.
    return nil
}

// MARK: - Set up the tap

var globalEventTap: CFMachPort?

guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: eventMask,
    callback: eventTapCallback,
    userInfo: nil
) else {
    fputs("""
    ERROR: Failed to create event tap.

    This almost always means the app is missing Accessibility permission.
    See the setup instructions accompanying this tool.
    """, stderr)
    exit(1)
}

globalEventTap = eventTap

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

print("Remapping button=3 -> Cmd+Opt+Right, button=4 -> Cmd+Opt+Left (browsers only). Press Ctrl+C to stop.")
fflush(stdout)

CFRunLoopRun()
