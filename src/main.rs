use clap::Parser;
use clap::Subcommand;

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

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::List => {
            println!("list not implemented yet");
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
    }
}
