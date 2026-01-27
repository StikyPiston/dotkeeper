use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

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

fn dotkeep_dir() -> PathBuf {
    dirs::home_dir()
        .expect("No home directory found")
        .join(".dotkeep")
}

fn state_file() -> PathBuf {
    dirs::home_dir()
        .expect("No home directory found")
        .join(".dotkeeper-state-json")
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

    if !path.exists() {
        return Ok(State {
            keep: None,
            links: vec![],
        });
    }

    let data =
        fs::read_to_string(&path).with_context(|| format!("Failed to read {}", path.display()))?;

    let state = serde_json::from_str(&data)
        .context("Failed to parse state file")?;

    Ok(state)
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
            println!("status not implemented yet");
        }
        Commands::Activate { keep } => {
            println!("activate keep: {keep}");
        }
        Commands::Deactivate => {
            println!("deactivate current keep");
        }
        Commands::Fetch { url } => {
            println!("fetch keep from: {url}");
        }
        _ => {}
    }
}
