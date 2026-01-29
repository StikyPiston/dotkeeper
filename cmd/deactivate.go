package cmd

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

func deactivateKeep() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		log.Fatal(err)
		return
	}

	stateFile := filepath.Join(homeDir, ".dotkeeper-state.json")

	state, err := os.ReadFile(stateFile)

	var data State

	err = json.Unmarshal(state, &data)
	if err != nil {
		log.Fatal(err)
		return
	}

	for _, link := range data.Links {
		target, err := ExpandPath(link.Target)

		info, err := os.Lstat(os.ExpandEnv(target))

		if err != nil {
			fmt.Println(" Error removing link: %s", err)
		}

		if info.Mode()&os.ModeSymlink == 0 {
			fmt.Println(" %s is not a symlink, skipping", target)
		}

		if info.Mode()&os.ModeSymlink != 0 {
			os.Remove(link.Target)
			fmt.Println("󰩺 Removed symlink: %s", target)
		}
	}
}

// deactivateCmd represents the deactivate command
var deactivateCmd = &cobra.Command{
	Use:   "deactivate",
	Short: "Deactivates the current keep",
	Run: func(cmd *cobra.Command, args []string) {
	},
}

func init() {
	rootCmd.AddCommand(deactivateCmd)
}
