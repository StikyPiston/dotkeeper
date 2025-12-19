// dotkeeper-swift

import Foundation

// MARK: - Data Models

struct Link: Codable {
    let source: String
    let target: String
}

struct State: Codable {
    var keep: String?
    var links: [Link]
}

struct Keep: Codable {
    let links: [Link]
}

// MARK: - Paths

let fileManager = FileManager.default
let homeDir     = fileManager.homeDirectoryForCurrentUser
let keepDir    = homeDir.appendingPathComponent(".dotkeep")
let stateFile   = homeDir.appendingPathComponent(".dotkeeper-state.json")

// MARK: Hostname
let hostname = ProcessInfo.processInfo.hostName

// MARK: - State Handling

func loadState() -> State {
    if fileManager.fileExists(atPath: stateFile.path) {
        do {
            let data = try Data(contentsOf: stateFile)
            return try JSONDecoder().decode(State.self, from: data)
        } catch {
            print(" Failed to load state: \(error)")
        }
    }
    return State(keep: nil, links: [])
}

func saveState(_ state: State) {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(state)
        try data.write(to: stateFile)
    } catch {
        print(" Failed to save state: \(error)")
    }
}

// MARK: - CLI Commands

func listKeeps() {
    do {
        let entries   = try fileManager.contentsOfDirectory(atPath: keepDir.path)
        let visible   = entries.filter { !$0.hasPrefix(".") }
        let keepPaths = visible.map { keepDir.appendingPathComponent($0) }
        let directories = keepPaths.filter { url in
            var isDirectory: ObjCBool = false
            return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
        
        print("󰻉 Available Keeps:")
        for dir in directories {
            print("- \(dir.lastPathComponent)")
        }
    } catch {
        print(" Failed to read keep directory: \(error)")
    }
}

func showStatus() {
    let state = loadState()
    if let keep = state.keep {
        print(" Active keep: \(keep)")
    } else {
        print(" No keeps active.")
    }
}

func deactivateCurrentKeep() {
    let state = loadState()
    for link in state.links {
        if let _ = try? FileManager.default.destinationOfSymbolicLink(atPath: link.target) {
            do {
                try FileManager.default.removeItem(atPath: link.target)
                print("\u{001B}[0;31m Removed symlink: \(link.target)\u{001B}[0;0m")
            } catch {
                print("\u{001B}[0;31m Could not remove symlink \(link.target): \(error)\u{001B}[0;0m")
            }
        }
    }
    saveState(State(keep: nil, links: []))
}

func activateKeep(keepName: String) {
    let keepPath = keepDir.appendingPathComponent(keepName)
    let keepFile = keepPath.appendingPathComponent("keep.json")


    guard fileManager.fileExists(atPath: keepFile.path) else {
        print(" No keep.json found in \(keepName)")
        return
    }

    deactivateCurrentKeep()

    do {
        let data = try Data(contentsOf: keepFile)
        let keep = try JSONDecoder().decode(Keep.self, from: data)
        
        var newLinks = keep.links

        let hSpecPath = keepPath.appendingPathComponent("hSpecs").appendingPathComponent("\(hostname).json")

        if fileManager.fileExists(atPath: hSpecPath.path) {
            do {
                let hSpecData = try Data(contentsOf: hSpecPath)
                let hSpec = try JSONDecoder().decode(Keep.self, from: hSpecData)

                print("\u{001B}[0;32m󰌨 Applying hSpec for host: \(hostname)\u{001B}[0;0m")

                newLinks.append(contentsOf: hSpec.links)
            } catch {
                print("\u{001B}[0;31m Error loading hSpec for \(hostname): \(error)\u{001B}[0;0m")
            }
        } else {
            print("\u{001B}[0;32m󰹎 No hSpec will be applied\u{001B}[0;0m")
        }

        for entry in newLinks {
            let source = keepPath.appendingPathComponent(entry.source).path
            let target = NSString(string: entry.target).expandingTildeInPath

            // Ensure parent directory exists
            do {
                try fileManager.createDirectory(
                    atPath: (target as NSString).deletingLastPathComponent,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                print("\u{001B}[0;31m Failed to create parent directory: \(error)\u{001B}[0;0m")
                continue
            }

            // Create the symlink
            do {
                try fileManager.createSymbolicLink(atPath: target, withDestinationPath: source)
                print(" Linked: \(target) → \(source)")
            } catch {
                print("\u{001B}[0;31m Failed to create symlink: \(error)\u{001B}[0;0m")
                continue
            }

            newLinks.append(Link(source: source, target: target))
        }

        let newState = State(keep: keepName, links: newLinks)
        saveState(newState)
        print("\u{001B}[0;32m Activated keep: \(keepName)\u{001B}[0;0m")

    } catch {
        print("\u{001B}[0;31m Failed to read or parse keep.json: \(error)\u{001B}[0;0m")
    }
}

func fetchKeep(url: String) {
    let keepsDir = keepDir

    print("\u{001B}[0;34m Installing keep: \(url)...\u{001B}[0;0m")

    let process = Process()
    process.currentDirectoryURL = keepsDir
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git", "clone", url]

    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("\u{001B}[0;32m Successfully installed keep \(url)\u{001B}[0;0m")
        } else {
            print("\u{001B}[0;31m Failed to install keep \(url), git exited with code \(process.terminationStatus)\u{001B}[0;0m")
        }
    } catch {
        print("\u{001B}[0;31m Error running git: \(error)\u{001B}[0;0m")
    }
}


// MARK: - CLI Entry Point

let args = CommandLine.arguments

if args.count > 1 {
    let command = args[1]

    switch command {
    case "list":
        listKeeps()
    case "status":
        showStatus()
    case "deactivate":
        deactivateCurrentKeep()
    case "activate":
        if args.count < 3 {
            print("Usage: dotkeeper activate <keep name>")
        } else {
            let keepName = args[2]
            activateKeep(keepName: keepName)
        }
    case "fetch":
        if args.count < 3 {
            print("Usage: dotkeeper fetch <url>")
        } else {
            let url = args[2]
            fetchKeep(url: url)
        }
    default:
        print("Unknown command")
    }
} else {
    print("Usage: dotkeeper <command>")
    print("> list            - Lists available keeps")
    print("> status          - Shows active keep")
    print("> deactivate      - Deactivates the current keep")
    print("> activate <keep> - Activates a keep")
    print("> fetch <url>     - Fetches a keep into ~/.dotkeep")
}
