use clap::{Parser, Subcommand};
use std::fs;
use std::path::PathBuf;

/// dotkeeper — manage dotfile keeps
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
    let home = std::env::var("HOME").expect("HOME not set");
    PathBuf::from(home).join(".dotkeep")
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
