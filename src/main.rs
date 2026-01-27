use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::path::Path;

#[derive(Debug, Serialize, Deserialize)]
struct State {
    keep: Option<String>,
    links: Vec<Link>,
}

#[derive(Debug, Serialize, Deserialize)]
struct Link {
    source: String,
    target: String,
}

// Set up CLI
#[derive(Parser)]
#[command(name = "dotkeeper")]
#[command(version)]
#[command(about = "Dotfile keep manager", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// List available keeps
    List,

    /// Show current keep status
    Status,

    /// Activate a keep
    Activate {
        /// Name of the keep to activate
        keep: String,
    },

    /// Deactivate the current keep
    Deactivate,

    /// Download a keep from a git repository
    Fetch {
        /// Git URL of the keep
        url: String,
    },
}

fn hostname() -> Result<String> {
    Ok(hostname::get()?
        .to_string_lossy()
        .to_string())
}

fn dotkeep_dir() -> PathBuf {
    dirs::home_dir()
        .expect("No home directory found")
        .join(".dotkeep")
}

fn state_file() -> PathBuf {
    dirs::home_dir()
        .expect("No home directory found")
        .join(".dotkeeper-state.json")
}

fn list_keeps() -> std::io::Result<()> {
    let dir = dotkeep_dir();

    if !dir.exists() {
        println!("{} does not exist, please create it.", dir.display()); // TODO: Colour red
        return Ok(());
    }

    println!("  Available keeps:"); // TODO: Colour blue

    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();

        if path.is_dir() {
            if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                if !name.starts_with(".") {
                    println!("- {}", name)
                }
            }
        }
    }

    Ok(())
}

fn load_state() -> Result<State> {
    let path = state_file();
    println!("Loaded path from {}", path.display());

    if !path.exists() {
        return Ok(State {
            keep: None,
            links: vec![],
        });
    }

    let data =
        fs::read_to_string(&path).with_context(|| format!("Failed to read {}", path.display()))?;

    let state = serde_json::from_str(&data).context("Failed to parse state file")?;

    Ok(state)
}

fn save_state(state: &State) -> Result<()> {
    let path = state_file();
    let json = serde_json::to_string_pretty(state)
        .context("Failed to serialize state")?;

    fs::write(&path, json)
        .with_context(|| format!("Failed to write {}", path.display()))?;

    Ok(())
}

fn status() -> Result<()> {
    let state = load_state()?;

    if let Some(keep) = state.keep {
        println!(" Active keep: {}", keep);
    } else {
        println!(" No active keep")
    }

    Ok(())
}

fn deactivate() -> Result<()> {
    let mut state = load_state()?;

    let keep = match &state.keep {
        Some(k) => k.clone(),
        None => {
            println!(" No active keep to deactivate");
            return Ok(());
        }
    };

    println!("󰌩 Deactivating keep: {}", keep);

    for link in &state.links {
        let target = Path::new(&link.target);

        if !target.exists() {
            continue;
        }

        let meta = fs::symlink_metadata(target)
            .with_context(|| format!(" Failed to stat {}", target.display()))?;

        if meta.file_type().is_symlink() {
            fs::remove_file(target)
                .with_context(|| format!(" Failed to remove {}", target.display()))?;
            println!(" Removed symlink: {}", target.display()); // <-- print after deletion
        }
    }

    state.keep = None;
    state.links.clear();

    save_state(&state)?;

    println!(" Keep deactivated");

    Ok(())
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::List => {
            if let Err(e) = list_keeps() {
                eprintln!("Error: {}", e);
            }
        }
        Commands::Status => {
            status();
        }
        Commands::Activate { keep } => {
            println!("activate keep: {keep}");
        }
        Commands::Deactivate => {
            deactivate();
        }
        Commands::Fetch { url } => {
            println!("fetch keep from: {url}");
        }
        _ => {}
    }
}
