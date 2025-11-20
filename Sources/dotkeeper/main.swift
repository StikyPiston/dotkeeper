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
                print(" Removed symlink: \(link.target)")
            } catch {
                print(" Could not remove symlink \(link.target): \(error)")
            }
        }
    }
    saveState(State(keep: nil, links: []))
}

func activateKeep(keepName: String) {
    let keepPath = keepDir.appendingPathComponent(keepName)
    let keepFile = keepPath.appendingPathComponent("plot.json")

    guard fileManager.fileExists(atPath: keepFile.path) else {
        print(" No keep.json found in \(keepName)")
        return
    }

    deactivateCurrentKeep()

    do {
        let data = try Data(contentsOf: keepFile)
        let keep = try JSONDecoder().decode(Keep.self, from: data)
        
        var newLinks: [Link] = []

        for entry in keep.links {
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
                print(" Failed to create parent directory: \(error)")
                continue
            }

            // Create the symlink
            do {
                try fileManager.createSymbolicLink(atPath: target, withDestinationPath: source)
                print(" Linked: \(target) → \(source)")
            } catch {
                print(" Failed to create symlink: \(error)")
                continue
            }

            newLinks.append(Link(source: source, target: target))
        }

        let newState = State(keep: keepName, links: newLinks)
        saveState(newState)
        print(" Activated keep: \(keepName)")

    } catch {
        print(" Failed to read or parse keep.json: \(error)")
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
    default:
        print("Unknown command")
    }
} else {
    print("Usage: dotkeeper <command>")
}
