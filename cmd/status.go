package cmd

import (
	"encoding/json"
	"log"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/fatih/color"
)

// statusCmd represents the status command
var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "See the currently active keep",
	Run: func(cmd *cobra.Command, args []string) {
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
			color.Red("󰌩 No active keep")
			return
		}

		if data.Keep != "" {
			color.Green(" Active keep: %s", data.Keep)
		} else {
			color.Red("󰌩 No active keep")
		}
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}
